#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

/// Runs lightweight synthetic benchmarks that measure system responsiveness.
/// Captures "before" and "after" snapshots so the user can see improvement.
class BenchmarkEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList results READ results NOTIFY resultsChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool hasBaseline READ hasBaseline NOTIFY resultsChanged)

public:
    explicit BenchmarkEngine(QObject *parent = nullptr);

    QVariantList results() const;
    bool running() const;
    bool hasBaseline() const;

    /// Run "before tweaks" baseline benchmark.
    Q_INVOKABLE void runBaseline();

    /// Run "after tweaks" benchmark and compute deltas.
    Q_INVOKABLE void runAfterTweaks();

    /// Clear all results.
    Q_INVOKABLE void reset();

signals:
    void resultsChanged();
    void runningChanged();

private:
    struct BenchResult {
        QString name;
        QString unit;
        double baseline = 0;
        double current = 0;
        bool higherIsBetter = true;  // true = higher score is better
    };

    void runBenchmarks(bool isBaseline);
    double benchMemoryLatency() const;
    double benchMemoryBandwidth() const;
    double benchCpuSingleThread() const;
    double benchCpuMultiThread() const;
    double benchDiskSequential() const;
    double benchSchedulingLatency() const;

    QList<BenchResult> m_results;
    bool m_running = false;
    bool m_hasBaseline = false;
};
