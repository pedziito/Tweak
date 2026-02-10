#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

#include "app/HardwareDetector.h"
#include "app/HardwareScorer.h"

/// Game FPS estimation engine.
/// Uses a hardware scoring model + per-game weight profiles to estimate
/// average FPS, 1% low FPS, and expected latency for popular titles.
class GameBenchmark : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList gameResults READ gameResults NOTIFY resultsChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(double networkLatency READ networkLatency NOTIFY networkDone)
    Q_PROPERTY(double storageSpeed READ storageSpeed NOTIFY storageDone)
    Q_PROPERTY(int systemLatencyScore READ systemLatencyScore NOTIFY resultsChanged)
    Q_PROPERTY(QString selectedResolution READ selectedResolution WRITE setSelectedResolution NOTIFY resolutionChanged)
    Q_PROPERTY(QString selectedQuality READ selectedQuality WRITE setSelectedQuality NOTIFY qualityChanged)

public:
    explicit GameBenchmark(QObject *parent = nullptr);

    void setHardware(const HardwareInfo &hw, const HardwareScorer *scorer);

    QVariantList gameResults() const;
    bool running() const;
    double networkLatency() const { return m_networkLatency; }
    double storageSpeed() const { return m_storageSpeed; }
    int systemLatencyScore() const { return m_systemLatencyScore; }
    QString selectedResolution() const { return m_resolution; }
    QString selectedQuality() const { return m_quality; }

    void setSelectedResolution(const QString &res);
    void setSelectedQuality(const QString &q);

    /// Run full estimation suite asynchronously.
    Q_INVOKABLE void runEstimation();

    /// Run quick network ping test.
    Q_INVOKABLE void runPingTest();

    /// Run storage speed test.
    Q_INVOKABLE void runStorageTest();

signals:
    void resultsChanged();
    void runningChanged();
    void networkDone();
    void storageDone();
    void resolutionChanged();
    void qualityChanged();

private:
    struct GameProfile {
        QString id;
        QString name;
        QString icon;
        double cpuWeight;     // how CPU-bound the game is (0-1)
        double gpuWeight;     // how GPU-bound
        double ramWeight;
        // FPS curve: baseFps at score=50, maxFps at score=100
        double baseFps;
        double maxFps;
        double onePercentMult; // 1% low as fraction of avg (typically 0.55-0.75)
    };

    QVariantMap estimateGame(const GameProfile &game, int cpuScore, int gpuScore,
                             int ramScore) const;
    double resolutionMultiplier() const;
    double qualityMultiplier() const;
    double measureNetworkLatency() const;
    double measureStorageSpeed() const;

    QList<GameProfile> m_profiles;
    QVariantList m_gameResults;
    bool m_running = false;
    double m_networkLatency = 0;  // ms
    double m_storageSpeed = 0;    // MB/s
    int m_systemLatencyScore = 0; // 0-100

    int m_cpuScore = 50;
    int m_gpuScore = 50;
    int m_ramScore = 50;

    QString m_resolution = "1080p";
    QString m_quality = "Medium";
};
