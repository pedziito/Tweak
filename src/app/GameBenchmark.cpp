#include "app/GameBenchmark.h"

#include <QProcess>
#include <QElapsedTimer>
#include <QStorageInfo>
#include <QTemporaryFile>
#include <QFile>
#include <QFutureWatcher>
#include <QtConcurrent/QtConcurrentRun>
#include <QCoreApplication>
#include <QRegularExpression>

#include <cmath>
#include <algorithm>
#include <numeric>
#include <random>
#include <cstring>

GameBenchmark::GameBenchmark(QObject *parent) : QObject(parent)
{
    // Initialise game profiles — tuned for 1080p medium-high settings
    m_profiles = {
        {"cs2",      "Counter-Strike 2",  "🎯", 0.50, 0.40, 0.10, 120, 550, 0.65},
        {"fortnite", "Fortnite",          "🏗️", 0.35, 0.55, 0.10, 60,  300, 0.60},
        {"warzone",  "Warzone",           "💣", 0.40, 0.50, 0.10, 50,  250, 0.55},
        {"valorant", "Valorant",          "🔫", 0.55, 0.30, 0.15, 150, 600, 0.70},
        {"apex",     "Apex Legends",      "🔥", 0.40, 0.50, 0.10, 60,  280, 0.58},
        {"gta5",     "GTA V",             "🚗", 0.35, 0.55, 0.10, 40,  200, 0.55},
        {"cyberpunk","Cyberpunk 2077",    "🤖", 0.30, 0.60, 0.10, 25,  160, 0.50},
        {"minecraft","Minecraft",         "⛏️", 0.60, 0.20, 0.20, 100, 500, 0.72},
    };
}

void GameBenchmark::setHardware(const HardwareInfo &, const HardwareScorer *scorer)
{
    if (!scorer) return;
    m_cpuScore = scorer->cpuScore();
    m_gpuScore = scorer->gpuScore();
    m_ramScore = scorer->ramScore();
}

// ─── FPS Estimation ────────────────────────────────────────────────────

QVariantMap GameBenchmark::estimateGame(const GameProfile &game, int cpuScore,
                                         int gpuScore, int ramScore) const
{
    // Compute a weighted effective score for this game
    double effScore = game.cpuWeight * cpuScore
                    + game.gpuWeight * gpuScore
                    + game.ramWeight * ramScore;

    // Logistic curve mapping score→FPS:  fps = base + (max-base) * sigmoid((score-40)/25)
    auto sigmoid = [](double x) { return 1.0 / (1.0 + std::exp(-x)); };
    double t = sigmoid((effScore - 40.0) / 22.0);
    double avgFps = game.baseFps + (game.maxFps - game.baseFps) * t;

    // Add slight random variation (±3%) for realism
    avgFps *= (0.97 + (std::rand() % 60) / 1000.0);
    avgFps = std::max(avgFps, 10.0);

    double onePercentLow = avgFps * game.onePercentMult;

    QVariantMap result;
    result["id"]           = game.id;
    result["name"]         = game.name;
    result["icon"]         = game.icon;
    result["avgFps"]       = static_cast<int>(std::round(avgFps));
    result["onePercentLow"]= static_cast<int>(std::round(onePercentLow));
    result["rating"]       = avgFps >= 240 ? "Excellent" :
                             avgFps >= 144 ? "Great" :
                             avgFps >= 60  ? "Good" :
                             avgFps >= 30  ? "Playable" : "Low";
    result["ratingColor"]  = avgFps >= 240 ? "#10b981" :
                             avgFps >= 144 ? "#22d3ee" :
                             avgFps >= 60  ? "#a78bfa" :
                             avgFps >= 30  ? "#f59e0b" : "#ef4444";
    return result;
}

// ─── Network Latency ───────────────────────────────────────────────────

double GameBenchmark::measureNetworkLatency() const
{
    // Ping multiple reliable targets, take median
    QStringList targets = {
        "1.1.1.1",       // Cloudflare
        "8.8.8.8",       // Google
        "208.67.222.222" // OpenDNS
    };

    QList<double> pings;

    for (const auto &target : targets) {
        QProcess proc;
#ifdef Q_OS_WIN
        proc.start("ping", QStringList() << "-n" << "3" << "-w" << "2000" << target);
#else
        proc.start("ping", QStringList() << "-c" << "3" << "-W" << "2" << target);
#endif
        if (!proc.waitForFinished(8000)) continue;

        QString output = proc.readAllStandardOutput();
        // Parse average from "Average = XXms" (Win) or "min/avg/max/mdev = .../XX/..." (Linux)
#ifdef Q_OS_WIN
        QRegularExpression re("Average\\s*=\\s*(\\d+)ms", QRegularExpression::CaseInsensitiveOption);
#else
        QRegularExpression re("([\\d.]+)/([\\d.]+)/([\\d.]+)/([\\d.]+)\\s*ms");
#endif
        auto match = re.match(output);
        if (match.hasMatch()) {
#ifdef Q_OS_WIN
            pings.append(match.captured(1).toDouble());
#else
            pings.append(match.captured(2).toDouble()); // avg field
#endif
        }
    }

    if (pings.isEmpty()) return -1; // no connectivity
    std::sort(pings.begin(), pings.end());
    return pings[pings.size() / 2]; // median
}

// ─── Storage Speed ─────────────────────────────────────────────────────

double GameBenchmark::measureStorageSpeed() const
{
    // Sequential write + read of 64 MB
    constexpr int blockSize = 1024 * 1024;  // 1 MB
    constexpr int totalMb = 64;
    QByteArray block(blockSize, '\0');

    // Fill with pseudo-random data
    std::mt19937 rng(42);
    auto *data = reinterpret_cast<uint32_t*>(block.data());
    for (int i = 0; i < blockSize / 4; ++i)
        data[i] = rng();

    QTemporaryFile tmp;
    if (!tmp.open()) return 0;

    QElapsedTimer timer;

    // Write
    timer.start();
    for (int i = 0; i < totalMb; ++i)
        tmp.write(block);
    tmp.flush();
#ifdef Q_OS_WIN
    // FlushFileBuffers not easily accessible, fsync via QFile
#endif
    double writeMs = timer.elapsed();

    // Read
    tmp.seek(0);
    timer.restart();
    for (int i = 0; i < totalMb; ++i)
        tmp.read(blockSize);
    double readMs = timer.elapsed();

    double totalMs = writeMs + readMs;
    if (totalMs < 1) totalMs = 1;
    // Average of write and read speed
    double writeMBs = (totalMb * 1000.0) / writeMs;
    double readMBs  = (totalMb * 1000.0) / readMs;
    return (writeMBs + readMBs) / 2.0;
}

// ─── Run full estimation ───────────────────────────────────────────────

void GameBenchmark::runEstimation()
{
    if (m_running) return;
    m_running = true;
    emit runningChanged();

    auto *watcher = new QFutureWatcher<QVariantList>(this);

    int cpu = m_cpuScore, gpu = m_gpuScore, ram = m_ramScore;
    QList<GameProfile> profiles = m_profiles;

    auto future = QtConcurrent::run([this, profiles, cpu, gpu, ram]() -> QVariantList {
        QVariantList results;
        for (const auto &game : profiles) {
            results.append(estimateGame(game, cpu, gpu, ram));
        }
        return results;
    });

    connect(watcher, &QFutureWatcher<QVariantList>::finished, this, [this, watcher]() {
        m_gameResults = watcher->result();

        // Compute system latency score: based on CPU score and RAM
        m_systemLatencyScore = std::clamp(
            static_cast<int>(m_cpuScore * 0.6 + m_ramScore * 0.25 + m_gpuScore * 0.15),
            0, 100);

        m_running = false;
        emit resultsChanged();
        emit runningChanged();
        watcher->deleteLater();
    });

    watcher->setFuture(future);
}

void GameBenchmark::runPingTest()
{
    auto *watcher = new QFutureWatcher<double>(this);
    auto future = QtConcurrent::run([this]() { return measureNetworkLatency(); });
    connect(watcher, &QFutureWatcher<double>::finished, this, [this, watcher]() {
        m_networkLatency = watcher->result();
        emit networkDone();
        watcher->deleteLater();
    });
    watcher->setFuture(future);
}

void GameBenchmark::runStorageTest()
{
    auto *watcher = new QFutureWatcher<double>(this);
    auto future = QtConcurrent::run([this]() { return measureStorageSpeed(); });
    connect(watcher, &QFutureWatcher<double>::finished, this, [this, watcher]() {
        m_storageSpeed = watcher->result();
        emit storageDone();
        watcher->deleteLater();
    });
    watcher->setFuture(future);
}

QVariantList GameBenchmark::gameResults() const { return m_gameResults; }
bool GameBenchmark::running() const { return m_running; }
