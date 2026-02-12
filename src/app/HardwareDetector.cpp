#include "app/HardwareDetector.h"

#include <QSysInfo>
#include <QProcess>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QDebug>

#ifdef Q_OS_WIN
#include <Windows.h>
#include <comdef.h>
#include <Wbemidl.h>
#pragma comment(lib, "wbemuuid.lib")
#endif

// ---------------------------------------------------------------------------
// WMI helpers (Windows-only)
// ---------------------------------------------------------------------------
#ifdef Q_OS_WIN
namespace {

struct ComInitGuard
{
    HRESULT hr;
    ComInitGuard()
    {
        hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
        if (SUCCEEDED(hr)) {
            // CoInitializeSecurity can only be called once per process.
            // If it fails (RPC_E_TOO_LATE), that's OK — it was already called.
            HRESULT secHr = CoInitializeSecurity(
                nullptr, -1, nullptr, nullptr,
                RPC_C_AUTHN_LEVEL_DEFAULT,
                RPC_C_IMP_LEVEL_IMPERSONATE,
                nullptr, EOAC_NONE, nullptr);
            (void)secHr; // Ignore — already set is fine
        }
    }
    ~ComInitGuard() { if (SUCCEEDED(hr)) CoUninitialize(); }
};

class WmiSession
{
public:
    bool open()
    {
        HRESULT hr = CoCreateInstance(CLSID_WbemLocator, nullptr,
                                      CLSCTX_INPROC_SERVER, IID_IWbemLocator,
                                      reinterpret_cast<void **>(&m_locator));
        if (FAILED(hr) || !m_locator) {
            qWarning() << "[HW] CoCreateInstance WbemLocator failed:" << Qt::hex << hr;
            return false;
        }

        hr = m_locator->ConnectServer(_bstr_t(L"ROOT\\CIMV2"), nullptr, nullptr,
                                      nullptr, 0, nullptr, nullptr, &m_services);
        if (FAILED(hr) || !m_services) {
            qWarning() << "[HW] ConnectServer ROOT\\CIMV2 failed:" << Qt::hex << hr;
            return false;
        }

        hr = CoSetProxyBlanket(m_services, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE,
                               nullptr, RPC_C_AUTHN_LEVEL_CALL,
                               RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE);
        if (FAILED(hr))
            qWarning() << "[HW] CoSetProxyBlanket failed:" << Qt::hex << hr;
        return SUCCEEDED(hr);
    }

    ~WmiSession()
    {
        if (m_services) m_services->Release();
        if (m_locator) m_locator->Release();
    }

    QString querySingleString(const wchar_t *wql, const wchar_t *field) const
    {
        IEnumWbemClassObject *pEnum = nullptr;
        HRESULT hr = m_services->ExecQuery(
            _bstr_t(L"WQL"), _bstr_t(wql),
            WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
            nullptr, &pEnum);
        if (FAILED(hr) || !pEnum) return {};

        IWbemClassObject *pObj = nullptr;
        ULONG ret = 0;
        hr = pEnum->Next(WBEM_INFINITE, 1, &pObj, &ret);
        QString result;
        if (SUCCEEDED(hr) && ret > 0 && pObj) {
            VARIANT v; VariantInit(&v);
            if (SUCCEEDED(pObj->Get(field, 0, &v, nullptr, nullptr)) && v.vt == VT_BSTR)
                result = QString::fromWCharArray(v.bstrVal);
            VariantClear(&v);
            pObj->Release();
        }
        pEnum->Release();
        return result.trimmed();
    }

    quint32 querySingleUInt32(const wchar_t *wql, const wchar_t *field) const
    {
        IEnumWbemClassObject *pEnum = nullptr;
        HRESULT hr = m_services->ExecQuery(
            _bstr_t(L"WQL"), _bstr_t(wql),
            WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
            nullptr, &pEnum);
        if (FAILED(hr) || !pEnum) return 0;

        IWbemClassObject *pObj = nullptr;
        ULONG ret = 0;
        hr = pEnum->Next(WBEM_INFINITE, 1, &pObj, &ret);
        quint32 result = 0;
        if (SUCCEEDED(hr) && ret > 0 && pObj) {
            VARIANT v; VariantInit(&v);
            if (SUCCEEDED(pObj->Get(field, 0, &v, nullptr, nullptr))) {
                if (v.vt == VT_I4 || v.vt == VT_UI4 || v.vt == VT_INT || v.vt == VT_UINT)
                    result = v.ulVal;
            }
            VariantClear(&v);
            pObj->Release();
        }
        pEnum->Release();
        return result;
    }

    QStringList queryStringList(const wchar_t *wql, const wchar_t *field) const
    {
        QStringList items;
        IEnumWbemClassObject *pEnum = nullptr;
        HRESULT hr = m_services->ExecQuery(
            _bstr_t(L"WQL"), _bstr_t(wql),
            WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
            nullptr, &pEnum);
        if (FAILED(hr) || !pEnum) return items;

        while (true) {
            IWbemClassObject *pObj = nullptr;
            ULONG ret = 0;
            hr = pEnum->Next(WBEM_INFINITE, 1, &pObj, &ret);
            if (FAILED(hr) || ret == 0 || !pObj) break;

            VARIANT v; VariantInit(&v);
            if (SUCCEEDED(pObj->Get(field, 0, &v, nullptr, nullptr)) && v.vt == VT_BSTR) {
                QString s = QString::fromWCharArray(v.bstrVal).trimmed();
                if (!s.isEmpty()) items.append(s);
            }
            VariantClear(&v);
            pObj->Release();
        }
        pEnum->Release();
        return items;
    }

    quint64 querySumUInt64(const wchar_t *wql, const wchar_t *field) const
    {
        quint64 sum = 0;
        IEnumWbemClassObject *pEnum = nullptr;
        HRESULT hr = m_services->ExecQuery(
            _bstr_t(L"WQL"), _bstr_t(wql),
            WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
            nullptr, &pEnum);
        if (FAILED(hr) || !pEnum) return sum;

        while (true) {
            IWbemClassObject *pObj = nullptr;
            ULONG ret = 0;
            hr = pEnum->Next(WBEM_INFINITE, 1, &pObj, &ret);
            if (FAILED(hr) || ret == 0 || !pObj) break;

            VARIANT v; VariantInit(&v);
            if (SUCCEEDED(pObj->Get(field, 0, &v, nullptr, nullptr))) {
                if (v.vt == VT_BSTR)        sum += _wtoi64(v.bstrVal);
                else if (v.vt == VT_UI8)     sum += v.ullVal;
                else if (v.vt == VT_I8)      sum += static_cast<quint64>(v.llVal);
            }
            VariantClear(&v);
            pObj->Release();
        }
        pEnum->Release();
        return sum;
    }

private:
    IWbemLocator  *m_locator  = nullptr;
    IWbemServices *m_services = nullptr;
};

} // anonymous namespace
#endif // Q_OS_WIN

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
HardwareInfo HardwareDetector::detect() const
{
#ifdef Q_OS_WIN
    return detectWindows();
#else
    return detectLinux();
#endif
}

// ---------------------------------------------------------------------------
// Linux fallback — reads /proc, /sys, lspci for dev-time testing
// ---------------------------------------------------------------------------
HardwareInfo HardwareDetector::detectLinux() const
{
    HardwareInfo info;

    // CPU from /proc/cpuinfo
    QFile cpuFile(QStringLiteral("/proc/cpuinfo"));
    if (cpuFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&cpuFile);
        int logicalCores = 0;
        QSet<int> coreIds;
        while (!in.atEnd()) {
            const QString line = in.readLine();
            if (line.startsWith(QStringLiteral("model name")) && info.cpuName.isEmpty()) {
                info.cpuName = line.mid(line.indexOf(QLatin1Char(':')) + 1).trimmed();
            }
            if (line.startsWith(QStringLiteral("cpu MHz")) && info.cpuMaxClockMhz == 0) {
                info.cpuMaxClockMhz = static_cast<quint64>(
                    line.mid(line.indexOf(QLatin1Char(':')) + 1).trimmed().toDouble());
            }
            if (line.startsWith(QStringLiteral("processor")))
                ++logicalCores;
            if (line.startsWith(QStringLiteral("core id"))) {
                int id = line.mid(line.indexOf(QLatin1Char(':')) + 1).trimmed().toInt();
                coreIds.insert(id);
            }
        }
        cpuFile.close();
        info.cpuThreads = logicalCores;
        info.cpuCores = coreIds.isEmpty() ? logicalCores : coreIds.size();
    }

    // RAM from /proc/meminfo
    QFile memFile(QStringLiteral("/proc/meminfo"));
    if (memFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&memFile);
        while (!in.atEnd()) {
            const QString line = in.readLine();
            if (line.startsWith(QStringLiteral("MemTotal"))) {
                // "MemTotal:       16384000 kB"
                static QRegularExpression rx(QStringLiteral("(\\d+)"));
                auto match = rx.match(line);
                if (match.hasMatch())
                    info.ramMb = match.captured(1).toULongLong() / 1024ULL;
                break;
            }
        }
        memFile.close();
    }

    // GPU via lspci
    {
        QProcess proc;
        proc.start(QStringLiteral("lspci"), QStringList() << QStringLiteral("-mm"));
        if (proc.waitForFinished(3000)) {
            const QString output = QString::fromUtf8(proc.readAllStandardOutput());
            for (const QString &line : output.split(QLatin1Char('\n'))) {
                if (line.contains(QStringLiteral("VGA"), Qt::CaseInsensitive) ||
                    line.contains(QStringLiteral("3D controller"), Qt::CaseInsensitive) ||
                    line.contains(QStringLiteral("Display"), Qt::CaseInsensitive))
                {
                    // Take the last quoted field or the whole line as GPU name
                    static QRegularExpression rxQuote(QStringLiteral("\"([^\"]+)\""));
                    QStringList parts;
                    auto it = rxQuote.globalMatch(line);
                    while (it.hasNext()) parts << it.next().captured(1);
                    if (parts.size() >= 3)
                        info.gpuName = parts.at(2); // device name
                    else if (!parts.isEmpty())
                        info.gpuName = parts.last();
                    break;
                }
            }
        }
        info.gpuVendor = classifyGpuVendor(info.gpuName);
    }

    // Motherboard from DMI
    {
        QFile f(QStringLiteral("/sys/devices/virtual/dmi/id/board_name"));
        if (f.open(QIODevice::ReadOnly | QIODevice::Text))
            info.motherboard = QString::fromUtf8(f.readAll()).trimmed();
    }

    // Storage from /sys/block
    {
        QProcess proc;
        proc.start(QStringLiteral("lsblk"),
                    QStringList() << QStringLiteral("-d") << QStringLiteral("-o")
                                  << QStringLiteral("NAME,MODEL,ROTA,TRAN") << QStringLiteral("-n"));
        if (proc.waitForFinished(3000)) {
            const QString output = QString::fromUtf8(proc.readAllStandardOutput());
            for (const QString &line : output.split(QLatin1Char('\n'))) {
                const QStringList parts = line.simplified().split(QLatin1Char(' '));
                if (parts.size() >= 2) {
                    // Reconstruct model name (may have spaces)
                    QString model = parts.mid(1, parts.size() - 3).join(QLatin1Char(' ')).trimmed();
                    if (model.isEmpty()) model = parts.at(0);
                    if (!model.isEmpty()) info.storage.append(model);

                    // Check rotation (0 = SSD) and transport (nvme)
                    if (parts.size() >= 3 && parts.at(parts.size() - 2) == QStringLiteral("0"))
                        info.hasSsd = true;
                    if (parts.size() >= 4 && parts.last().contains(QStringLiteral("nvme"), Qt::CaseInsensitive)) {
                        info.hasNvme = true;
                        info.hasSsd = true;
                    }
                }
            }
        }
    }

    if (info.cpuName.isEmpty()) info.cpuName = QSysInfo::currentCpuArchitecture();
    if (info.gpuName.isEmpty()) info.gpuName = QStringLiteral("Unknown");
    if (info.gpuVendor.isEmpty()) info.gpuVendor = QStringLiteral("Unknown");
    if (info.motherboard.isEmpty()) info.motherboard = QStringLiteral("Unknown");

    // ── Lag 2: Low-Level (Linux) ──

    // CPU Cache from /sys
    {
        QFile l2(QStringLiteral("/sys/devices/system/cpu/cpu0/cache/index2/size"));
        if (l2.open(QIODevice::ReadOnly)) {
            QString val = QString::fromUtf8(l2.readAll()).trimmed();
            if (val.endsWith(QLatin1Char('K')))
                info.cpuL2CacheKb = val.chopped(1).toUInt();
            else
                info.cpuL2CacheKb = val.toUInt();
        }
        QFile l3(QStringLiteral("/sys/devices/system/cpu/cpu0/cache/index3/size"));
        if (l3.open(QIODevice::ReadOnly)) {
            QString val = QString::fromUtf8(l3.readAll()).trimmed();
            if (val.endsWith(QLatin1Char('K')))
                info.cpuL3CacheKb = val.chopped(1).toUInt();
            else if (val.endsWith(QLatin1Char('M')))
                info.cpuL3CacheKb = val.chopped(1).toUInt() * 1024;
            else
                info.cpuL3CacheKb = val.toUInt();
        }
    }

    // RAM type & speed from dmidecode (requires root — best effort)
    {
        QProcess proc;
        proc.start(QStringLiteral("dmidecode"), QStringList()
                    << QStringLiteral("-t") << QStringLiteral("memory"));
        if (proc.waitForFinished(3000)) {
            QString out = QString::fromUtf8(proc.readAllStandardOutput());
            for (const QString &line : out.split(QLatin1Char('\n'))) {
                QString trimmed = line.trimmed();
                if (trimmed.startsWith(QStringLiteral("Type:")) && info.ramType.isEmpty()) {
                    info.ramType = trimmed.mid(5).trimmed();
                }
                if (trimmed.startsWith(QStringLiteral("Configured Memory Speed:")) && info.ramSpeedMhz == 0) {
                    static QRegularExpression rxNum(QStringLiteral("(\\d+)"));
                    auto m = rxNum.match(trimmed);
                    if (m.hasMatch()) info.ramSpeedMhz = m.captured(1).toUInt();
                }
            }
        }
    }

    // Disk sizes
    {
        QProcess proc;
        proc.start(QStringLiteral("lsblk"),
                    QStringList() << QStringLiteral("-d") << QStringLiteral("-b")
                                  << QStringLiteral("-o") << QStringLiteral("SIZE,TRAN")
                                  << QStringLiteral("-n"));
        if (proc.waitForFinished(3000)) {
            QString out = QString::fromUtf8(proc.readAllStandardOutput());
            for (const QString &line : out.split(QLatin1Char('\n'))) {
                QStringList parts = line.simplified().split(QLatin1Char(' '));
                if (parts.size() >= 1) {
                    quint64 bytes = parts.at(0).toULongLong();
                    if (bytes > 0)
                        info.diskSizesGb.append(bytes / (1024ULL * 1024ULL * 1024ULL));
                    if (parts.size() >= 2)
                        info.diskInterfaces.append(parts.at(1));
                }
            }
        }
    }

    // ── Lag 3: Firmware / SMBIOS (Linux) ──

    // BIOS version & date
    {
        QFile bv(QStringLiteral("/sys/devices/virtual/dmi/id/bios_version"));
        if (bv.open(QIODevice::ReadOnly))
            info.biosVersion = QString::fromUtf8(bv.readAll()).trimmed();
        QFile bd(QStringLiteral("/sys/devices/virtual/dmi/id/bios_date"));
        if (bd.open(QIODevice::ReadOnly))
            info.biosDate = QString::fromUtf8(bd.readAll()).trimmed();
    }

    // Chassis type
    {
        QFile ct(QStringLiteral("/sys/devices/virtual/dmi/id/chassis_type"));
        if (ct.open(QIODevice::ReadOnly)) {
            quint32 code = QString::fromUtf8(ct.readAll()).trimmed().toUInt();
            info.chassisType = classifyChassisType(code);
        }
    }

    // Secure Boot
    {
        QProcess proc;
        proc.start(QStringLiteral("mokutil"), QStringList() << QStringLiteral("--sb-state"));
        if (proc.waitForFinished(3000)) {
            QString out = QString::fromUtf8(proc.readAllStandardOutput());
            info.secureBootEnabled = out.contains(QStringLiteral("enabled"), Qt::CaseInsensitive);
        }
    }

    // TPM
    {
        info.tpmVersion = QStringLiteral("Not detected");
        QFile tpm(QStringLiteral("/sys/class/tpm/tpm0/tpm_version_major"));
        if (tpm.open(QIODevice::ReadOnly)) {
            QString ver = QString::fromUtf8(tpm.readAll()).trimmed();
            info.tpmVersion = ver + QStringLiteral(".0");
        }
    }

    if (info.ramType.isEmpty()) info.ramType = QStringLiteral("Unknown");
    if (info.biosVersion.isEmpty()) info.biosVersion = QStringLiteral("Unknown");
    if (info.chassisType.isEmpty()) info.chassisType = QStringLiteral("Unknown");

    return info;
}

// ---------------------------------------------------------------------------
// Windows — WMI-based detection
// ---------------------------------------------------------------------------
HardwareInfo HardwareDetector::detectWindows() const
{
    HardwareInfo info;
#ifdef Q_OS_WIN
    ComInitGuard comInit;
    if (FAILED(comInit.hr)) {
        qWarning() << "[HW] CoInitializeEx failed:" << Qt::hex << comInit.hr;
        // Fallback: get at least CPU arch
        info.cpuName = QSysInfo::currentCpuArchitecture();
        return info;
    }

    WmiSession wmi;
    if (!wmi.open()) {
        qWarning() << "[HW] WMI session failed to open";
        info.cpuName = QSysInfo::currentCpuArchitecture();
        return info;
    }

    // CPU
    info.cpuName        = wmi.querySingleString(L"SELECT Name FROM Win32_Processor", L"Name");
    info.cpuCores       = static_cast<int>(wmi.querySingleUInt32(L"SELECT NumberOfCores FROM Win32_Processor", L"NumberOfCores"));
    info.cpuThreads     = static_cast<int>(wmi.querySingleUInt32(L"SELECT ThreadCount FROM Win32_Processor", L"ThreadCount"));
    info.cpuMaxClockMhz = wmi.querySingleUInt32(L"SELECT MaxClockSpeed FROM Win32_Processor", L"MaxClockSpeed");

    // GPU — skip virtual/Microsoft Basic Display
    QStringList gpuNames = wmi.queryStringList(L"SELECT Name FROM Win32_VideoController", L"Name");
    for (const QString &g : gpuNames) {
        if (g.contains(QStringLiteral("Microsoft"), Qt::CaseInsensitive) ||
            g.contains(QStringLiteral("Virtual"), Qt::CaseInsensitive))
            continue;
        info.gpuName = g;
        break;
    }
    if (info.gpuName.isEmpty() && !gpuNames.isEmpty())
        info.gpuName = gpuNames.first();
    info.gpuVendor = classifyGpuVendor(info.gpuName);

    // Motherboard
    info.motherboard = wmi.querySingleString(L"SELECT Product FROM Win32_BaseBoard", L"Product");

    // RAM (sum of all DIMMs)
    const quint64 totalBytes = wmi.querySumUInt64(L"SELECT Capacity FROM Win32_PhysicalMemory", L"Capacity");
    info.ramMb = totalBytes / (1024ULL * 1024ULL);

    // If WMI RAM query returns 0, try GlobalMemoryStatusEx as fallback
    if (info.ramMb == 0) {
        MEMORYSTATUSEX memInfo;
        memInfo.dwLength = sizeof(MEMORYSTATUSEX);
        if (GlobalMemoryStatusEx(&memInfo)) {
            info.ramMb = static_cast<quint64>(memInfo.ullTotalPhys / (1024ULL * 1024ULL));
        }
    }

    // Storage
    info.storage = wmi.queryStringList(L"SELECT Model FROM Win32_DiskDrive", L"Model");
    const QStringList mediaTypes = wmi.queryStringList(L"SELECT MediaType FROM Win32_DiskDrive", L"MediaType");
    const QStringList interfaces = wmi.queryStringList(L"SELECT InterfaceType FROM Win32_DiskDrive", L"InterfaceType");

    for (const QString &m : info.storage) {
        if (m.contains(QStringLiteral("SSD"), Qt::CaseInsensitive) ||
            m.contains(QStringLiteral("NVMe"), Qt::CaseInsensitive))
        {
            info.hasSsd = true;
        }
        if (m.contains(QStringLiteral("NVMe"), Qt::CaseInsensitive))
            info.hasNvme = true;
    }
    for (const QString &mt : mediaTypes) {
        if (mt.contains(QStringLiteral("SSD"), Qt::CaseInsensitive))
            info.hasSsd = true;
    }
    for (const QString &iface : interfaces) {
        if (iface.contains(QStringLiteral("NVMe"), Qt::CaseInsensitive) ||
            iface.contains(QStringLiteral("SCSI"), Qt::CaseInsensitive))
        {
            info.hasNvme = true;
            info.hasSsd = true;
        }
    }

    // ── Lag 2: Low-Level ──

    // RAM type & speed from SMBIOS (Win32_PhysicalMemory)
    {
        quint32 memType = wmi.querySingleUInt32(
            L"SELECT SMBIOSMemoryType FROM Win32_PhysicalMemory", L"SMBIOSMemoryType");
        info.ramType = classifyRamType(memType);
        info.ramSpeedMhz = wmi.querySingleUInt32(
            L"SELECT ConfiguredClockSpeed FROM Win32_PhysicalMemory", L"ConfiguredClockSpeed");
        if (info.ramSpeedMhz == 0)
            info.ramSpeedMhz = wmi.querySingleUInt32(
                L"SELECT Speed FROM Win32_PhysicalMemory", L"Speed");
    }

    // GPU VRAM & driver from Win32_VideoController
    {
        quint32 vram = wmi.querySingleUInt32(
            L"SELECT AdapterRAM FROM Win32_VideoController", L"AdapterRAM");
        info.gpuVramMb = vram / (1024U * 1024U);
        // AdapterRAM caps at 4 GB (32-bit). For modern GPUs, try registry fallback.
        if (info.gpuVramMb <= 4096 && !info.gpuName.isEmpty()) {
            // Try qvideo memory size from DXGI via WMI MSFT namespace (simpler: just report capped)
            // Most games tools do the same unless using DXGI directly
        }
        info.gpuDriverVersion = wmi.querySingleString(
            L"SELECT DriverVersion FROM Win32_VideoController", L"DriverVersion");
    }

    // CPU Cache from Win32_CacheMemory
    {
        // L2 (Purpose = "L2 Cache" or Level = 4)
        info.cpuL2CacheKb = wmi.querySingleUInt32(
            L"SELECT MaxCacheSize FROM Win32_CacheMemory WHERE Level = 4", L"MaxCacheSize");
        // L3 (Level = 5)
        info.cpuL3CacheKb = wmi.querySingleUInt32(
            L"SELECT MaxCacheSize FROM Win32_CacheMemory WHERE Level = 5", L"MaxCacheSize");
        // Some systems report total L2 across cores. Also try Processor class.
        if (info.cpuL3CacheKb == 0)
            info.cpuL3CacheKb = wmi.querySingleUInt32(
                L"SELECT L3CacheSize FROM Win32_Processor", L"L3CacheSize");
        if (info.cpuL2CacheKb == 0)
            info.cpuL2CacheKb = wmi.querySingleUInt32(
                L"SELECT L2CacheSize FROM Win32_Processor", L"L2CacheSize");
    }

    // Disk interfaces and sizes
    {
        info.diskInterfaces = wmi.queryStringList(
            L"SELECT InterfaceType FROM Win32_DiskDrive", L"InterfaceType");
        // Disk sizes in GB
        IEnumWbemClassObject *pEnum = nullptr;
        // We'll use querySumUInt64 per drive — simplified approach: just get sizes
        QStringList sizesStr = wmi.queryStringList(
            L"SELECT Size FROM Win32_DiskDrive", L"Size");
        for (const QString &s : sizesStr) {
            quint64 bytes = s.toULongLong();
            if (bytes > 0)
                info.diskSizesGb.append(bytes / (1024ULL * 1024ULL * 1024ULL));
        }
    }

    // ── Lag 3: Firmware / SMBIOS ──

    // BIOS info
    info.biosVersion = wmi.querySingleString(
        L"SELECT SMBIOSBIOSVersion FROM Win32_BIOS", L"SMBIOSBIOSVersion");
    if (info.biosVersion.isEmpty())
        info.biosVersion = wmi.querySingleString(
            L"SELECT Version FROM Win32_BIOS", L"Version");
    info.biosDate = wmi.querySingleString(
        L"SELECT ReleaseDate FROM Win32_BIOS", L"ReleaseDate");
    // Format BIOS date: "20231215000000.000000+000" → "2023-12-15"
    if (info.biosDate.length() >= 8) {
        info.biosDate = info.biosDate.left(4) + QStringLiteral("-")
                      + info.biosDate.mid(4, 2) + QStringLiteral("-")
                      + info.biosDate.mid(6, 2);
    }

    // Chassis type (Desktop / Laptop)
    {
        quint32 chassisCode = wmi.querySingleUInt32(
            L"SELECT ChassisTypes FROM Win32_SystemEnclosure", L"ChassisTypes");
        // ChassisTypes is actually an array; querySingleUInt32 gets first element usually
        // Fallback: use PCSystemType
        if (chassisCode == 0) {
            chassisCode = wmi.querySingleUInt32(
                L"SELECT PCSystemType FROM Win32_ComputerSystem", L"PCSystemType");
            // 1=Desktop, 2=Mobile/Laptop, 3=Workstation
            if (chassisCode == 2) info.chassisType = QStringLiteral("Laptop");
            else if (chassisCode == 1 || chassisCode == 3) info.chassisType = QStringLiteral("Desktop");
            else info.chassisType = QStringLiteral("Unknown");
        } else {
            info.chassisType = classifyChassisType(chassisCode);
        }
    }

    // Secure Boot via registry (faster than WMI UEFI namespace)
    {
        HKEY hKey;
        if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
                          L"SYSTEM\\CurrentControlSet\\Control\\SecureBoot\\State",
                          0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            DWORD val = 0, size = sizeof(val);
            if (RegQueryValueExW(hKey, L"UEFISecureBootEnabled", nullptr, nullptr,
                                 reinterpret_cast<LPBYTE>(&val), &size) == ERROR_SUCCESS)
                info.secureBootEnabled = (val == 1);
            RegCloseKey(hKey);
        }
    }

    // TPM version via Win32_Tpm (requires WMI ROOT\CIMV2\Security\MicrosoftTpm namespace)
    // This often requires admin privileges. Try it, fallback to "Not detected".
    {
        info.tpmVersion = QStringLiteral("Not detected");
        // Try reading from registry as non-admin fallback
        HKEY hKey;
        if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
                          L"SYSTEM\\CurrentControlSet\\Services\\TPM\\WMI",
                          0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            // If the key exists, TPM is present
            info.tpmVersion = QStringLiteral("Present");
            RegCloseKey(hKey);
        }
        // For the actual version, try WMI (may fail without admin)
        // The ManufacturerVersion from ROOT\CIMV2\Security\MicrosoftTpm
        // is unreachable from user-mode WMI without elevation, so skip.
    }

    // Fallbacks for empty values
    if (info.cpuName.isEmpty()) info.cpuName = QSysInfo::currentCpuArchitecture();
    if (info.gpuName.isEmpty()) info.gpuName = QStringLiteral("Unknown");
    if (info.motherboard.isEmpty()) info.motherboard = QStringLiteral("Unknown");
    if (info.ramType.isEmpty()) info.ramType = QStringLiteral("Unknown");
    if (info.biosVersion.isEmpty()) info.biosVersion = QStringLiteral("Unknown");
    if (info.chassisType.isEmpty()) info.chassisType = QStringLiteral("Unknown");

    qDebug() << "[HW] Detected:" << info.cpuName << "|" << info.gpuName
             << "|" << info.gpuVendor << "| RAM" << info.ramMb << "MB"
             << info.ramType << "@" << info.ramSpeedMhz << "MHz"
             << "| Cores" << info.cpuCores << "/" << info.cpuThreads
             << "| VRAM" << info.gpuVramMb << "MB"
             << "| BIOS" << info.biosVersion
             << "| Chassis" << info.chassisType;
#endif
    return info;
}

QString HardwareDetector::classifyGpuVendor(const QString &gpuName)
{
    if (gpuName.contains(QStringLiteral("NVIDIA"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("GeForce"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("RTX"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("GTX"), Qt::CaseInsensitive))
        return QStringLiteral("NVIDIA");
    if (gpuName.contains(QStringLiteral("AMD"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("Radeon"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("RX "), Qt::CaseInsensitive))
        return QStringLiteral("AMD");
    if (gpuName.contains(QStringLiteral("Intel"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("UHD"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("Iris"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("Arc"), Qt::CaseInsensitive))
        return QStringLiteral("Intel");
    return QStringLiteral("Unknown");
}

QString HardwareDetector::classifyRamType(quint32 smbiosType)
{
    // SMBIOS Memory Type codes (from DMTF spec)
    switch (smbiosType) {
    case 20: return QStringLiteral("DDR");
    case 21: return QStringLiteral("DDR2");
    case 22: // DDR2 FB-DIMM
             return QStringLiteral("DDR2");
    case 24: return QStringLiteral("DDR3");
    case 26: return QStringLiteral("DDR4");
    case 30: // LPDDR4
             return QStringLiteral("LPDDR4");
    case 34: return QStringLiteral("DDR5");
    case 35: // LPDDR5
             return QStringLiteral("LPDDR5");
    default: return QStringLiteral("Unknown");
    }
}

QString HardwareDetector::classifyChassisType(quint32 code)
{
    // SMBIOS System Enclosure types
    switch (code) {
    case 3: case 4: case 5: case 6: case 7: case 15: case 16:
        return QStringLiteral("Desktop");
    case 8: case 9: case 10: case 14: case 31:
        return QStringLiteral("Laptop");
    case 11: case 12:
        return QStringLiteral("Handheld");
    case 17: case 23:
        return QStringLiteral("Server");
    case 30:
        return QStringLiteral("Tablet");
    default:
        return QStringLiteral("Unknown");
    }
}
