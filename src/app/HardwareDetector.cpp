#include "app/HardwareDetector.h"

#include <QSysInfo>

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
            CoInitializeSecurity(nullptr, -1, nullptr, nullptr,
                                RPC_C_AUTHN_LEVEL_DEFAULT,
                                RPC_C_IMP_LEVEL_IMPERSONATE,
                                nullptr, EOAC_NONE, nullptr);
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
        if (FAILED(hr) || !m_locator) return false;

        hr = m_locator->ConnectServer(_bstr_t(L"ROOT\\CIMV2"), nullptr, nullptr,
                                      nullptr, 0, nullptr, nullptr, &m_services);
        if (FAILED(hr) || !m_services) return false;

        hr = CoSetProxyBlanket(m_services, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE,
                               nullptr, RPC_C_AUTHN_LEVEL_CALL,
                               RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE);
        return SUCCEEDED(hr);
    }

    ~WmiSession()
    {
        if (m_services) m_services->Release();
        if (m_locator) m_locator->Release();
    }

    // Run a WQL query, return first match for |field| as QString.
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
        return result;
    }

    // Run a WQL query, return first match for |field| as uint32.
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

    // Return all matching string values.
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
                QString s = QString::fromWCharArray(v.bstrVal);
                if (!s.isEmpty()) items.append(s);
            }
            VariantClear(&v);
            pObj->Release();
        }
        pEnum->Release();
        return items;
    }

    // Sum a numeric field across all rows (used for RAM capacity).
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

    // Check whether any row contains |substring| in |field|.
    bool queryContains(const wchar_t *wql, const wchar_t *field, const QString &substring) const
    {
        for (const QString &s : queryStringList(wql, field)) {
            if (s.contains(substring, Qt::CaseInsensitive))
                return true;
        }
        return false;
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
    HardwareInfo info;
    info.cpuName = QSysInfo::currentCpuArchitecture();
    info.gpuName = QStringLiteral("Unknown");
    info.gpuVendor = QStringLiteral("Unknown");
    info.motherboard = QStringLiteral("Unknown");
    return info;
#endif
}

HardwareInfo HardwareDetector::detectWindows() const
{
    HardwareInfo info;
#ifdef Q_OS_WIN
    ComInitGuard comInit;
    if (FAILED(comInit.hr)) return info;

    WmiSession wmi;
    if (!wmi.open()) return info;

    // CPU
    info.cpuName        = wmi.querySingleString(L"SELECT Name FROM Win32_Processor", L"Name");
    info.cpuCores       = static_cast<int>(wmi.querySingleUInt32(L"SELECT NumberOfCores FROM Win32_Processor", L"NumberOfCores"));
    info.cpuThreads     = static_cast<int>(wmi.querySingleUInt32(L"SELECT ThreadCount FROM Win32_Processor", L"ThreadCount"));
    info.cpuMaxClockMhz = wmi.querySingleUInt32(L"SELECT MaxClockSpeed FROM Win32_Processor", L"MaxClockSpeed");

    // GPU
    info.gpuName   = wmi.querySingleString(L"SELECT Name FROM Win32_VideoController", L"Name");
    info.gpuVendor = classifyGpuVendor(info.gpuName);

    // Motherboard
    info.motherboard = wmi.querySingleString(L"SELECT Product FROM Win32_BaseBoard", L"Product");

    // RAM (sum of all DIMMs)
    const quint64 totalBytes = wmi.querySumUInt64(L"SELECT Capacity FROM Win32_PhysicalMemory", L"Capacity");
    info.ramMb = totalBytes / (1024ULL * 1024ULL);

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
#endif
    return info;
}

QString HardwareDetector::classifyGpuVendor(const QString &gpuName)
{
    if (gpuName.contains(QStringLiteral("NVIDIA"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("GeForce"), Qt::CaseInsensitive))
        return QStringLiteral("NVIDIA");
    if (gpuName.contains(QStringLiteral("AMD"), Qt::CaseInsensitive) ||
        gpuName.contains(QStringLiteral("Radeon"), Qt::CaseInsensitive))
        return QStringLiteral("AMD");
    if (gpuName.contains(QStringLiteral("Intel"), Qt::CaseInsensitive))
        return QStringLiteral("Intel");
    return QStringLiteral("Unknown");
}
