#include "app/BenchmarkEngine.h"

#include <QThread>
#include <QElapsedTimer>
#include <QTemporaryFile>
#include <QFile>
#include <QStandardPaths>
#include <QtConcurrent/QtConcurrent>
#include <QFuture>
#include <QFutureWatcher>

#include <cstdlib>
#include <cstring>
#include <cmath>
#include <numeric>
#include <vector>
#include <random>
#include <algorithm>
#include <atomic>
#include <thread>

BenchmarkEngine::BenchmarkEngine(QObject *parent)
    : QObject(parent)
{
}

QVariantList BenchmarkEngine::results() const
{
    QVariantList list;
    for (const BenchResult &r : m_results) {
        QVariantMap m;
        m[QStringLiteral("name")]           = r.name;
        m[QStringLiteral("unit")]           = r.unit;
        m[QStringLiteral("baseline")]       = r.baseline;
        m[QStringLiteral("current")]        = r.current;
        m[QStringLiteral("higherIsBetter")] = r.higherIsBetter;

        // Calculate improvement percentage
        if (r.baseline > 0 && r.current > 0) {
            double pct;
            if (r.higherIsBetter)
                pct = ((r.current - r.baseline) / r.baseline) * 100.0;
            else
                pct = ((r.baseline - r.current) / r.baseline) * 100.0;
            m[QStringLiteral("improvement")] = std::round(pct * 10.0) / 10.0;
        } else {
            m[QStringLiteral("improvement")] = 0.0;
        }
        list.append(m);
    }
    return list;
}

bool BenchmarkEngine::running() const { return m_running; }
bool BenchmarkEngine::hasBaseline() const { return m_hasBaseline; }

void BenchmarkEngine::runBaseline()
{
    runBenchmarks(true);
}

void BenchmarkEngine::runAfterTweaks()
{
    runBenchmarks(false);
}

void BenchmarkEngine::reset()
{
    m_results.clear();
    m_hasBaseline = false;
    emit resultsChanged();
}

void BenchmarkEngine::runBenchmarks(bool isBaseline)
{
    if (m_running) return;
    m_running = true;
    emit runningChanged();

    // Run benchmarks in a thread to keep UI responsive
    auto *watcher = new QFutureWatcher<void>(this);
    connect(watcher, &QFutureWatcher<void>::finished, this, [this, watcher, isBaseline]() {
        watcher->deleteLater();

        if (isBaseline) {
            m_hasBaseline = true;
        }

        m_running = false;
        emit runningChanged();
        emit resultsChanged();
    });

    watcher->setFuture(QtConcurrent::run([this, isBaseline]() {
        // Initialize result slots on first call
        if (m_results.isEmpty()) {
            m_results = {
                { QStringLiteral("Memory Latency"),    QStringLiteral("ns"),    0, 0, false },
                { QStringLiteral("Memory Bandwidth"),  QStringLiteral("GB/s"),  0, 0, true  },
                { QStringLiteral("CPU Single-Thread"), QStringLiteral("score"), 0, 0, true  },
                { QStringLiteral("CPU Multi-Thread"),  QStringLiteral("score"), 0, 0, true  },
                { QStringLiteral("Disk Sequential"),   QStringLiteral("MB/s"),  0, 0, true  },
                { QStringLiteral("Scheduling Jitter"), QStringLiteral("μs"),    0, 0, false },
            };
        }

        // Run each benchmark
        auto scores = {
            benchMemoryLatency(),
            benchMemoryBandwidth(),
            benchCpuSingleThread(),
            benchCpuMultiThread(),
            benchDiskSequential(),
            benchSchedulingLatency()
        };

        int i = 0;
        for (double val : scores) {
            if (i < m_results.size()) {
                if (isBaseline)
                    m_results[i].baseline = val;
                else
                    m_results[i].current = val;
            }
            ++i;
        }
    }));
}

// ---------------------------------------------------------------------------
// Memory Latency — pointer-chasing benchmark (ns per access)
// ---------------------------------------------------------------------------
double BenchmarkEngine::benchMemoryLatency() const
{
    constexpr int SIZE = 4 * 1024 * 1024; // 4M entries = 32MB
    constexpr int ITERS = 2000000;

    std::vector<int> arr(SIZE);
    // Create a random linked list through the array
    std::iota(arr.begin(), arr.end(), 0);
    std::mt19937 rng(42);
    std::shuffle(arr.begin(), arr.end(), rng);

    // Convert to pointer-chasing chain
    std::vector<int> chain(SIZE);
    for (int i = 0; i < SIZE; ++i)
        chain[i] = arr[i];

    volatile int idx = 0;
    QElapsedTimer timer;
    timer.start();

    for (int i = 0; i < ITERS; ++i)
        idx = chain[idx];

    const double elapsedNs = timer.nsecsElapsed();
    const double nsPerAccess = elapsedNs / ITERS;

    // Use idx to prevent optimization
    (void)idx;

    return std::round(nsPerAccess * 10.0) / 10.0;
}

// ---------------------------------------------------------------------------
// Memory Bandwidth — sequential read (GB/s)
// ---------------------------------------------------------------------------
double BenchmarkEngine::benchMemoryBandwidth() const
{
    constexpr size_t SIZE = 64 * 1024 * 1024; // 64MB
    constexpr int ITERS = 4;

    std::vector<char> buffer(SIZE);
    std::memset(buffer.data(), 0xAA, SIZE);

    volatile long long sum = 0;
    QElapsedTimer timer;
    timer.start();

    for (int iter = 0; iter < ITERS; ++iter) {
        const auto *p = reinterpret_cast<const long long *>(buffer.data());
        long long localSum = 0;
        for (size_t i = 0; i < SIZE / sizeof(long long); ++i)
            localSum += p[i];
        sum += localSum;
    }

    const double elapsedSec = timer.nsecsElapsed() / 1e9;
    const double totalBytes = static_cast<double>(SIZE) * ITERS;
    const double gbPerSec = (totalBytes / (1024.0 * 1024.0 * 1024.0)) / elapsedSec;

    (void)sum;

    return std::round(gbPerSec * 100.0) / 100.0;
}

// ---------------------------------------------------------------------------
// CPU Single-Thread — arithmetic workload (score = iterations / time)
// ---------------------------------------------------------------------------
double BenchmarkEngine::benchCpuSingleThread() const
{
    constexpr int ITERS = 5000000;

    QElapsedTimer timer;
    timer.start();

    volatile double result = 1.0;
    for (int i = 1; i <= ITERS; ++i) {
        result = result * 1.000001 + 0.000001;
        result = std::sin(result) + std::cos(result * 0.5);
        result = std::abs(result);
    }

    const double elapsedMs = timer.nsecsElapsed() / 1e6;
    (void)result;

    // Score = iterations per millisecond
    double score = static_cast<double>(ITERS) / elapsedMs;
    return std::round(score);
}

// ---------------------------------------------------------------------------
// CPU Multi-Thread — same workload spread across all cores
// ---------------------------------------------------------------------------
double BenchmarkEngine::benchCpuMultiThread() const
{
    const int numThreads = static_cast<int>(std::thread::hardware_concurrency());
    if (numThreads <= 0) return 0;

    constexpr int ITERS_PER_THREAD = 5000000;

    std::atomic<int> readyCount{0};
    QElapsedTimer timer;

    auto worker = [&readyCount, ITERS_PER_THREAD]() {
        readyCount.fetch_add(1);
        volatile double result = 1.0;
        for (int i = 1; i <= ITERS_PER_THREAD; ++i) {
            result = result * 1.000001 + 0.000001;
            result = std::sin(result) + std::cos(result * 0.5);
            result = std::abs(result);
        }
        (void)result;
    };

    timer.start();

    std::vector<std::thread> threads;
    threads.reserve(numThreads);
    for (int i = 0; i < numThreads; ++i)
        threads.emplace_back(worker);
    for (auto &t : threads)
        t.join();

    const double elapsedMs = timer.nsecsElapsed() / 1e6;

    // Total iterations across all threads / ms
    double score = static_cast<double>(ITERS_PER_THREAD) * numThreads / elapsedMs;
    return std::round(score);
}

// ---------------------------------------------------------------------------
// Disk Sequential — write+read speed (MB/s)
// ---------------------------------------------------------------------------
double BenchmarkEngine::benchDiskSequential() const
{
    const QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    const QString filePath = tempDir + QStringLiteral("/tweak_bench.tmp");

    constexpr size_t BLOCK  = 1024 * 1024; // 1MB blocks
    constexpr int BLOCKS    = 64;           // 64MB total

    std::vector<char> block(BLOCK, 0x55);

    // Write benchmark
    QElapsedTimer timer;
    timer.start();

    {
        QFile f(filePath);
        if (!f.open(QIODevice::WriteOnly)) return 0;
        for (int i = 0; i < BLOCKS; ++i)
            f.write(block.data(), BLOCK);
        f.flush();
    }

    const double writeNs = timer.nsecsElapsed();

    // Read benchmark
    timer.restart();

    {
        QFile f(filePath);
        if (!f.open(QIODevice::ReadOnly)) return 0;
        while (f.read(block.data(), BLOCK) > 0) {}
    }

    const double readNs = timer.nsecsElapsed();

    // Clean up
    QFile::remove(filePath);

    const double totalBytes = static_cast<double>(BLOCK) * BLOCKS;
    const double avgSec = ((writeNs + readNs) / 2.0) / 1e9;
    const double mbPerSec = (totalBytes / (1024.0 * 1024.0)) / avgSec;

    return std::round(mbPerSec * 10.0) / 10.0;
}

// ---------------------------------------------------------------------------
// Scheduling Jitter — measures timer consistency (μs variance)
// ---------------------------------------------------------------------------
double BenchmarkEngine::benchSchedulingLatency() const
{
    constexpr int SAMPLES = 1000;
    constexpr int TARGET_US = 1000; // Target 1ms sleep

    std::vector<double> deltas;
    deltas.reserve(SAMPLES);

    for (int i = 0; i < SAMPLES; ++i) {
        QElapsedTimer timer;
        timer.start();

        // Sleep for ~1ms
        QThread::usleep(TARGET_US);

        const double actualUs = timer.nsecsElapsed() / 1000.0;
        const double jitter = std::abs(actualUs - TARGET_US);
        deltas.push_back(jitter);
    }

    // Return median jitter (more stable than mean)
    std::sort(deltas.begin(), deltas.end());
    double median = deltas[SAMPLES / 2];

    return std::round(median * 10.0) / 10.0;
}
