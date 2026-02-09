#pragma once

#include <QObject>
#include <QTimer>

/// Provides live system metrics (CPU usage, RAM, uptime, storage).
/// Updates every second via QTimer.
class SystemMonitor : public QObject
{
    Q_OBJECT

    Q_PROPERTY(double cpuUsage       READ cpuUsage       NOTIFY updated)
    Q_PROPERTY(double ramUsage       READ ramUsage       NOTIFY updated)
    Q_PROPERTY(double ramUsedGb      READ ramUsedGb      NOTIFY updated)
    Q_PROPERTY(double ramTotalGb     READ ramTotalGb     NOTIFY updated)
    Q_PROPERTY(double storageUsage   READ storageUsage   NOTIFY updated)
    Q_PROPERTY(double storageUsedGb  READ storageUsedGb  NOTIFY updated)
    Q_PROPERTY(double storageTotalGb READ storageTotalGb NOTIFY updated)
    Q_PROPERTY(int    uptimeMinutes  READ uptimeMinutes  NOTIFY updated)
    Q_PROPERTY(QString uptimeText    READ uptimeText     NOTIFY updated)

public:
    explicit SystemMonitor(QObject *parent = nullptr);

    double  cpuUsage() const;
    double  ramUsage() const;
    double  ramUsedGb() const;
    double  ramTotalGb() const;
    double  storageUsage() const;
    double  storageUsedGb() const;
    double  storageTotalGb() const;
    int     uptimeMinutes() const;
    QString uptimeText() const;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void updated();

private slots:
    void poll();

private:
    void pollCpu();
    void pollRam();
    void pollStorage();
    void pollUptime();

    QTimer m_timer;

    double m_cpuUsage       = 0;
    double m_ramUsedGb      = 0;
    double m_ramTotalGb     = 0;
    double m_storageUsedGb  = 0;
    double m_storageTotalGb = 0;
    int    m_uptimeMinutes  = 0;

#ifdef Q_OS_WIN
    quint64 m_prevIdleTime  = 0;
    quint64 m_prevKernelTime = 0;
    quint64 m_prevUserTime  = 0;
    bool    m_firstCpuPoll  = true;
#else
    quint64 m_prevTotal = 0;
    quint64 m_prevIdle  = 0;
    bool    m_firstCpuPoll = true;
#endif
};
