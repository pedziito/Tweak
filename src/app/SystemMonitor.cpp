#include "app/SystemMonitor.h"

#include <QFile>
#include <QStorageInfo>
#include <QSysInfo>
#include <QTextStream>

#ifdef Q_OS_WIN
#include <Windows.h>
#endif

SystemMonitor::SystemMonitor(QObject *parent)
    : QObject(parent)
{
    m_timer.setInterval(1500);
    connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::poll);
    poll(); // initial read
}

double  SystemMonitor::cpuUsage()       const { return m_cpuUsage; }
double  SystemMonitor::ramUsage()       const { return m_ramTotalGb > 0 ? (m_ramUsedGb / m_ramTotalGb) * 100.0 : 0; }
double  SystemMonitor::ramUsedGb()      const { return m_ramUsedGb; }
double  SystemMonitor::ramTotalGb()     const { return m_ramTotalGb; }
double  SystemMonitor::storageUsage()   const { return m_storageTotalGb > 0 ? (m_storageUsedGb / m_storageTotalGb) * 100.0 : 0; }
double  SystemMonitor::storageUsedGb()  const { return m_storageUsedGb; }
double  SystemMonitor::storageTotalGb() const { return m_storageTotalGb; }
int     SystemMonitor::uptimeMinutes()  const { return m_uptimeMinutes; }

QString SystemMonitor::uptimeText() const
{
    int h = m_uptimeMinutes / 60;
    int m = m_uptimeMinutes % 60;
    if (h > 0)
        return QString::number(h) + QStringLiteral("h ") + QString::number(m) + QStringLiteral("m");
    return QString::number(m) + QStringLiteral(" min");
}

void SystemMonitor::start() { m_timer.start(); }
void SystemMonitor::stop()  { m_timer.stop(); }

void SystemMonitor::poll()
{
    pollCpu();
    pollRam();
    pollStorage();
    pollUptime();
    emit updated();
}

// ---------------------------------------------------------------------------
// CPU usage
// ---------------------------------------------------------------------------
void SystemMonitor::pollCpu()
{
#ifdef Q_OS_WIN
    FILETIME idle, kernel, user;
    if (GetSystemTimes(&idle, &kernel, &user)) {
        auto toU64 = [](const FILETIME &ft) -> quint64 {
            return (static_cast<quint64>(ft.dwHighDateTime) << 32) | ft.dwLowDateTime;
        };
        quint64 i = toU64(idle), k = toU64(kernel), u = toU64(user);
        if (!m_firstCpuPoll) {
            quint64 di = i - m_prevIdleTime;
            quint64 dk = k - m_prevKernelTime;
            quint64 du = u - m_prevUserTime;
            quint64 total = dk + du;
            if (total > 0)
                m_cpuUsage = (1.0 - static_cast<double>(di) / static_cast<double>(total)) * 100.0;
        }
        m_prevIdleTime = i;
        m_prevKernelTime = k;
        m_prevUserTime = u;
        m_firstCpuPoll = false;
    }
#else
    QFile f(QStringLiteral("/proc/stat"));
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString line = QTextStream(&f).readLine(); // "cpu  ..."
        f.close();
        QStringList parts = line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (parts.size() >= 5) {
            quint64 user   = parts[1].toULongLong();
            quint64 nice   = parts[2].toULongLong();
            quint64 system = parts[3].toULongLong();
            quint64 idle   = parts[4].toULongLong();
            quint64 iowait = parts.size() > 5 ? parts[5].toULongLong() : 0;

            quint64 total = user + nice + system + idle + iowait;
            for (int i = 6; i < parts.size(); ++i)
                total += parts[i].toULongLong();

            quint64 idleTotal = idle + iowait;

            if (!m_firstCpuPoll && total > m_prevTotal) {
                quint64 dt = total - m_prevTotal;
                quint64 di = idleTotal - m_prevIdle;
                m_cpuUsage = (1.0 - static_cast<double>(di) / static_cast<double>(dt)) * 100.0;
            }
            m_prevTotal = total;
            m_prevIdle = idleTotal;
            m_firstCpuPoll = false;
        }
    }
#endif
}

// ---------------------------------------------------------------------------
// RAM
// ---------------------------------------------------------------------------
void SystemMonitor::pollRam()
{
#ifdef Q_OS_WIN
    MEMORYSTATUSEX mem;
    mem.dwLength = sizeof(MEMORYSTATUSEX);
    if (GlobalMemoryStatusEx(&mem)) {
        m_ramTotalGb = static_cast<double>(mem.ullTotalPhys) / (1024.0 * 1024.0 * 1024.0);
        double available = static_cast<double>(mem.ullAvailPhys) / (1024.0 * 1024.0 * 1024.0);
        m_ramUsedGb = m_ramTotalGb - available;
    }
#else
    QFile f(QStringLiteral("/proc/meminfo"));
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        quint64 total = 0, available = 0;
        QTextStream in(&f);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith(QStringLiteral("MemTotal:")))
                total = line.split(QLatin1Char(' '), Qt::SkipEmptyParts).at(1).toULongLong();
            else if (line.startsWith(QStringLiteral("MemAvailable:")))
                available = line.split(QLatin1Char(' '), Qt::SkipEmptyParts).at(1).toULongLong();
        }
        f.close();
        m_ramTotalGb = static_cast<double>(total) / (1024.0 * 1024.0); // kB -> GB
        m_ramUsedGb = m_ramTotalGb - static_cast<double>(available) / (1024.0 * 1024.0);
    }
#endif
}

// ---------------------------------------------------------------------------
// Storage (root/C: drive)
// ---------------------------------------------------------------------------
void SystemMonitor::pollStorage()
{
    QStorageInfo root = QStorageInfo::root();
    if (root.isValid()) {
        m_storageTotalGb = static_cast<double>(root.bytesTotal()) / (1024.0 * 1024.0 * 1024.0);
        double free = static_cast<double>(root.bytesAvailable()) / (1024.0 * 1024.0 * 1024.0);
        m_storageUsedGb = m_storageTotalGb - free;
    }
}

// ---------------------------------------------------------------------------
// Uptime
// ---------------------------------------------------------------------------
void SystemMonitor::pollUptime()
{
#ifdef Q_OS_WIN
    m_uptimeMinutes = static_cast<int>(GetTickCount64() / 60000ULL);
#else
    QFile f(QStringLiteral("/proc/uptime"));
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        double secs = QTextStream(&f).readLine().split(QLatin1Char(' ')).first().toDouble();
        m_uptimeMinutes = static_cast<int>(secs / 60.0);
        f.close();
    }
#endif
}
