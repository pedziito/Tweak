#pragma once

#include <QString>
#include <QStringList>

struct HardwareInfo
{
    // ── Lag 1: OS-niveau ──
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

    // ── Lag 2: Low-Level ──
    QString ramType;         // "DDR4" | "DDR5" | "Unknown"
    quint32 ramSpeedMhz = 0;
    quint32 gpuVramMb = 0;
    QString gpuDriverVersion;
    quint32 cpuL2CacheKb = 0;
    quint32 cpuL3CacheKb = 0;
    QStringList diskInterfaces;  // "NVMe", "SATA", "SCSI" per drive
    QList<quint64> diskSizesGb;  // size per drive in GB

    // ── Lag 3: Firmware / SMBIOS ──
    QString biosVersion;
    QString biosDate;
    QString tpmVersion;      // "2.0", "1.2", "Not detected"
    bool secureBootEnabled = false;
    QString chassisType;     // "Desktop" | "Laptop" | "Unknown"
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
    static QString classifyRamType(quint32 smbiosMemoryType);
    static QString classifyChassisType(quint32 chassisTypeCode);
};
