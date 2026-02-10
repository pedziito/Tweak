#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

#include "app/HardwareDetector.h"

/// Hardware scoring system — computes Gaming Score, Performance Score,
/// identifies bottlenecks, and classifies system tier.
class HardwareScorer : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int gamingScore       READ gamingScore       NOTIFY scored)
    Q_PROPERTY(int performanceScore  READ performanceScore  NOTIFY scored)
    Q_PROPERTY(int cpuScore          READ cpuScore          NOTIFY scored)
    Q_PROPERTY(int gpuScore          READ gpuScore          NOTIFY scored)
    Q_PROPERTY(int ramScore          READ ramScore          NOTIFY scored)
    Q_PROPERTY(int storageScore      READ storageScore      NOTIFY scored)
    Q_PROPERTY(QString tier          READ tier              NOTIFY scored)
    Q_PROPERTY(QString bottleneck    READ bottleneck        NOTIFY scored)
    Q_PROPERTY(QVariantList insights READ insights          NOTIFY scored)

public:
    explicit HardwareScorer(QObject *parent = nullptr);

    void score(const HardwareInfo &hw);

    int gamingScore() const       { return m_gamingScore; }
    int performanceScore() const  { return m_performanceScore; }
    int cpuScore() const          { return m_cpuScore; }
    int gpuScore() const          { return m_gpuScore; }
    int ramScore() const          { return m_ramScore; }
    int storageScore() const      { return m_storageScore; }
    QString tier() const          { return m_tier; }
    QString bottleneck() const    { return m_bottleneck; }
    QVariantList insights() const { return m_insights; }

signals:
    void scored();

private:
    int scoreCpu(const HardwareInfo &hw) const;
    int scoreGpu(const HardwareInfo &hw) const;
    int scoreRam(const HardwareInfo &hw) const;
    int scoreStorage(const HardwareInfo &hw) const;
    QString classifyTier(int overall) const;
    QString detectBottleneck() const;
    QVariantList generateInsights(const HardwareInfo &hw) const;

    int m_gamingScore = 0;
    int m_performanceScore = 0;
    int m_cpuScore = 0;
    int m_gpuScore = 0;
    int m_ramScore = 0;
    int m_storageScore = 0;
    QString m_tier;
    QString m_bottleneck;
    QVariantList m_insights;
};
