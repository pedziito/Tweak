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

    // Fallbacks for empty values
    if (info.cpuName.isEmpty()) info.cpuName = QSysInfo::currentCpuArchitecture();
    if (info.gpuName.isEmpty()) info.gpuName = QStringLiteral("Unknown");
    if (info.motherboard.isEmpty()) info.motherboard = QStringLiteral("Unknown");

    qDebug() << "[HW] Detected:" << info.cpuName << "|" << info.gpuName
             << "|" << info.gpuVendor << "| RAM" << info.ramMb << "MB"
             << "| Cores" << info.cpuCores << "/" << info.cpuThreads;
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
