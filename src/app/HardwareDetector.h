#pragma once

#include <QString>
#include <QStringList>

struct HardwareInfo
{
    QString cpuName;
    QString gpuName;
    QString gpuVendor;       // "NVIDIA" | "AMD" | "Intel" | "Unknown"
    quint64 ramMb = 0;
    int cpuCores = 0;
    int cpuThreads = 0;
    quint64 cpuMaxClockMhz = 0;
    QString motherboard;
    QStringList storage;     // drive model names
    bool hasSsd = false;
    bool hasNvme = false;
};

class HardwareDetector
{
public:
    HardwareDetector() = default;
    HardwareInfo detect() const;

private:
    HardwareInfo detectWindows() const;
    HardwareInfo detectLinux() const;
    static QString classifyGpuVendor(const QString &gpuName);
};
