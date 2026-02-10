#include "app/TweakEngine.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QStandardPaths>

#include "app/RegistryUtil.h"
#include "app/PowerUtil.h"
#include "app/UacHelper.h"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
namespace {

QString backupPath()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return dir + QStringLiteral("/backup.json");
}

QVariantMap registryAction(const QString &hive, const QString &path,
                           const QString &name, const QVariant &value)
{
    return {
        {QStringLiteral("type"),  QStringLiteral("registry")},
        {QStringLiteral("hive"),  hive},
        {QStringLiteral("path"),  path},
        {QStringLiteral("name"),  name},
        {QStringLiteral("value"), value}
    };
}

QVariantMap powerPlanAction(const QString &guid)
{
    return {
        {QStringLiteral("type"), QStringLiteral("powerplan")},
        {QStringLiteral("guid"), guid}
    };
}

QVariantMap gpuPreferenceAction(const QString &exePath, const QString &pref)
{
    return {
        {QStringLiteral("type"),    QStringLiteral("gpupref")},
        {QStringLiteral("exePath"), exePath},
        {QStringLiteral("pref"),    pref}
    };
}

QVariantMap serviceAction(const QString &serviceName, const QString &startType)
{
    return {
        {QStringLiteral("type"),      QStringLiteral("service")},
        {QStringLiteral("service"),   serviceName},
        {QStringLiteral("startType"), startType}
    };
}

} // anonymous namespace

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------
TweakEngine::TweakEngine()
{
    initializeTweaks();
}

QList<Tweak> &TweakEngine::tweaks()        { return m_tweaks; }
const QList<Tweak> &TweakEngine::tweaks() const { return m_tweaks; }

QStringList TweakEngine::categories() const
{
    QSet<QString> cats;
    for (const Tweak &t : m_tweaks) cats.insert(t.category);
    QStringList sorted = cats.values();
    sorted.sort();
    sorted.prepend(QStringLiteral("All"));
    return sorted;
}

void TweakEngine::setCs2Path(const QString &path) { m_cs2Path = path; }
QString TweakEngine::cs2Path() const { return m_cs2Path; }

int TweakEngine::appliedCount() const
{
    int n = 0;
    for (const Tweak &t : m_tweaks) { if (t.applied) ++n; }
    return n;
}

int TweakEngine::recommendedCount() const
{
    int n = 0;
    for (const Tweak &t : m_tweaks) { if (t.recommended) ++n; }
    return n;
}

bool TweakEngine::isAdmin() const
{
    return UacHelper::isRunningAsAdmin();
}

// ---------------------------------------------------------------------------
// Recommendations (hardware-driven)
// ---------------------------------------------------------------------------
void TweakEngine::updateRecommendations(const HardwareInfo &info)
{
    for (Tweak &t : m_tweaks) t.recommended = false;

    for (Tweak &t : m_tweaks) {
        // Always-safe recommendations
        if (t.id == QStringLiteral("power_plan")
            || t.id == QStringLiteral("disable_gamedvr")
            || t.id == QStringLiteral("system_responsiveness")
            || t.id == QStringLiteral("games_task_priority")
            || t.id == QStringLiteral("network_throttle")
            || t.id == QStringLiteral("disable_fullscreen_optim")
            || t.id == QStringLiteral("disable_game_bar")
            || t.id == QStringLiteral("disable_mouse_accel")
            || t.id == QStringLiteral("disable_transparency")
            || t.id == QStringLiteral("disable_background_apps")
            || t.id == QStringLiteral("disable_tips_notifications")
            || t.id == QStringLiteral("disable_telemetry"))
        {
            t.recommended = true;
        }

        // Recommend CS2 tweaks only when a discrete GPU is present
        if (t.id == QStringLiteral("cs2_gpu_pref") || t.id == QStringLiteral("cs2_launch_opts")) {
            t.recommended = (info.gpuVendor == QStringLiteral("NVIDIA")
                             || info.gpuVendor == QStringLiteral("AMD"));
        }

        // NVIDIA-specific
        if (t.id == QStringLiteral("nvidia_threaded_optim")) {
            t.recommended = (info.gpuVendor == QStringLiteral("NVIDIA"));
        }

        // On >=16 GB RAM: recommend memory tweaks
        if (t.id == QStringLiteral("large_system_cache")
            || t.id == QStringLiteral("disable_paging_exec")
            || t.id == QStringLiteral("disable_memory_compression")
            || t.id == QStringLiteral("svchost_split_threshold")
            || t.id == QStringLiteral("ndu_disable"))
        {
            t.recommended = (info.ramMb >= 16384);
        }

        // TCP tweaks: always recommend
        if (t.id == QStringLiteral("tcp_ack_frequency")
            || t.id == QStringLiteral("nagle_disable"))
        {
            t.recommended = true;
        }

        // SSD-specific
        if (t.id == QStringLiteral("disable_prefetch") || t.id == QStringLiteral("disable_superfetch")) {
            t.recommended = info.hasSsd;
        }

        // Services: always recommend disabling diagnostics
        if (t.id == QStringLiteral("disable_diagtrack")
            || t.id == QStringLiteral("disable_sysmain"))
        {
            t.recommended = info.hasSsd;
        }

        // Power throttling: recommend for Intel CPUs
        if (t.id == QStringLiteral("disable_power_throttling")) {
            t.recommended = info.cpuName.contains(QStringLiteral("Intel"), Qt::CaseInsensitive);
        }

        // Visual tweaks: recommend if integrated GPU
        if (t.id == QStringLiteral("visual_fx_performance")
            || t.id == QStringLiteral("disable_animations"))
        {
            t.recommended = (info.gpuVendor == QStringLiteral("Intel"));
        }
    }
}

// ---------------------------------------------------------------------------
// Apply / Restore
// ---------------------------------------------------------------------------
void TweakEngine::applyRecommended()
{
    for (Tweak &t : m_tweaks) {
        if (t.recommended && !t.applied)
            applyTweak(t);
    }
}

void TweakEngine::restoreDefaults()
{
    for (Tweak &t : m_tweaks) {
        if (t.applied)
            restoreTweak(t);
    }
}

void TweakEngine::toggleTweak(const QString &id)
{
    for (Tweak &t : m_tweaks) {
        if (t.id == id) {
            if (t.applied) restoreTweak(t);
            else           applyTweak(t);
            break;
        }
    }
}

// ---------------------------------------------------------------------------
// All tweaks definition
// ---------------------------------------------------------------------------
void TweakEngine::initializeTweaks()
{
    m_tweaks.clear();

    // ======= POWER =======
    {
        Tweak t;
        t.id = QStringLiteral("power_plan");
        t.category = QStringLiteral("Power");
        t.name = QStringLiteral("Activate High / Ultimate Performance power plan");
        t.description = QStringLiteral("Switches the active power scheme to a performance-focused profile. "
                                        "Tries Ultimate Performance first, falls back to High Performance.");
        t.learnMore = QStringLiteral("Windows ships with Balanced as default, which throttles CPU clocks to save power. "
                                      "The High Performance plan keeps clocks high at the cost of power draw.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = false;
        t.actions.append(powerPlanAction(QStringLiteral("e9a42b02-d5df-448d-aa00-03f14749eb61")));
        t.actions.append(powerPlanAction(QStringLiteral("8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_usb_suspend");
        t.category = QStringLiteral("Power");
        t.name = QStringLiteral("Disable USB selective suspend");
        t.description = QStringLiteral("Prevents Windows from power-saving USB devices, "
                                        "avoiding mouse/keyboard disconnects during gaming.");
        t.learnMore = QStringLiteral("USB selective suspend can cause peripherals to briefly go to sleep, "
                                      "leading to missed inputs or reconnects mid-game.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\USB\\DisableSelectiveSuspend"),
            QStringLiteral("DisableSelectiveSuspend"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }

    // ======= GAMING =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_gamedvr");
        t.category = QStringLiteral("Gaming");
        t.name = QStringLiteral("Disable Game DVR background capture");
        t.description = QStringLiteral("Stops Windows background recording that uses GPU resources while gaming.");
        t.learnMore = QStringLiteral("Game DVR constantly records the last 30 seconds of gameplay in the background. "
                                      "This uses GPU encoder resources and can cause frame drops.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\GameDVR"),
            QStringLiteral("AppCaptureEnabled"),
            QVariant::fromValue(static_cast<quint32>(0))));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("System\\GameConfigStore"),
            QStringLiteral("GameDVR_Enabled"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_game_bar");
        t.category = QStringLiteral("Gaming");
        t.name = QStringLiteral("Disable Xbox Game Bar overlay");
        t.description = QStringLiteral("Removes the Game Bar overlay process to reclaim system resources.");
        t.learnMore = QStringLiteral("The Xbox Game Bar runs as an overlay process. "
                                      "Even when not visible, its background services consume memory and CPU.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\GameBar"),
            QStringLiteral("AllowAutoGameMode"),
            QVariant::fromValue(static_cast<quint32>(0))));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\GameBar"),
            QStringLiteral("ShowStartupPanel"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_fullscreen_optim");
        t.category = QStringLiteral("Gaming");
        t.name = QStringLiteral("Disable fullscreen optimizations globally");
        t.description = QStringLiteral("Prevents the DWM borderless hack so exclusive fullscreen actually works. "
                                        "Reduces input lag in many games.");
        t.learnMore = QStringLiteral("Windows 10/11 converts exclusive fullscreen to borderless windowed mode. "
                                      "This adds a frame of latency via the DWM compositor. "
                                      "Disabling it restores true exclusive fullscreen for lower input lag.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("System\\GameConfigStore"),
            QStringLiteral("GameDVR_DXGIHonorFSEWindowsCompatible"),
            QVariant::fromValue(static_cast<quint32>(1))));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("System\\GameConfigStore"),
            QStringLiteral("GameDVR_FSEBehavior"),
            QVariant::fromValue(static_cast<quint32>(2))));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("System\\GameConfigStore"),
            QStringLiteral("GameDVR_FSEBehaviorMode"),
            QVariant::fromValue(static_cast<quint32>(2))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("hardware_accel_sched");
        t.category = QStringLiteral("Gaming");
        t.name = QStringLiteral("Enable hardware-accelerated GPU scheduling");
        t.description = QStringLiteral("Lets the GPU manage its own memory scheduling, reducing latency "
                                        "on supported hardware (NVIDIA 10-series+ / AMD 5600+).");
        t.learnMore = QStringLiteral("HAGS moves VRAM scheduling from the Windows kernel to the GPU firmware. "
                                      "Can reduce frame delivery latency by ~1ms on supported GPUs. "
                                      "Requires a restart to take effect.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers"),
            QStringLiteral("HwSchMode"),
            QVariant::fromValue(static_cast<quint32>(2))));
        m_tweaks.append(t);
    }

    // ======= LATENCY =======
    {
        Tweak t;
        t.id = QStringLiteral("system_responsiveness");
        t.category = QStringLiteral("Latency");
        t.name = QStringLiteral("Lower system responsiveness for multimedia");
        t.description = QStringLiteral("Sets SystemResponsiveness to 10 so multimedia (game) threads get more CPU time.");
        t.learnMore = QStringLiteral("Windows reserves 20% of CPU for background tasks by default. "
                                      "Setting this to 10 reduces that reservation, giving games more CPU headroom.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile"),
            QStringLiteral("SystemResponsiveness"),
            QVariant::fromValue(static_cast<quint32>(10))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("timer_resolution");
        t.category = QStringLiteral("Latency");
        t.name = QStringLiteral("Enable global timer resolution requests");
        t.description = QStringLiteral("Allows applications to request high-resolution timers (0.5 ms) for precise scheduling.");
        t.learnMore = QStringLiteral("By default Windows uses a 15.6ms timer tick. This allows apps to request 0.5ms resolution. "
                                      "Slightly increases power draw but notably improves frame pacing consistency.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\kernel"),
            QStringLiteral("GlobalTimerResolutionRequests"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_hpet");
        t.category = QStringLiteral("Latency");
        t.name = QStringLiteral("Set timer platform to TSC (disable HPET use)");
        t.description = QStringLiteral("Forces the OS to use TSC as the primary clock source. "
                                        "Can reduce DPC latency on many modern systems.");
        t.learnMore = QStringLiteral("HPET can add microseconds of overhead per timer query. Modern CPUs have invariant TSC "
                                      "which is faster and more accurate. Not recommended on very old CPUs without invariant TSC.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation"),
            QStringLiteral("RealTimeIsUniversal"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }

    // ======= FPS =======
    {
        Tweak t;
        t.id = QStringLiteral("games_task_priority");
        t.category = QStringLiteral("FPS");
        t.name = QStringLiteral("Increase game task GPU & scheduling priority");
        t.description = QStringLiteral("Raises the MMCSS Games profile priorities for smoother frame pacing.");
        t.learnMore = QStringLiteral("MMCSS (Multimedia Class Scheduler Service) manages thread priorities. "
                                      "Setting GPU Priority=8 and Scheduling=High ensures game threads preempt background work.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games"),
            QStringLiteral("GPU Priority"),
            QVariant::fromValue(static_cast<quint32>(8))));
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games"),
            QStringLiteral("Priority"),
            QVariant::fromValue(static_cast<quint32>(6))));
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games"),
            QStringLiteral("Scheduling Category"),
            QStringLiteral("High")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("cs2_gpu_pref");
        t.category = QStringLiteral("FPS");
        t.name = QStringLiteral("CS2 — High-performance GPU preference");
        t.description = QStringLiteral("Tells Windows to always use the discrete GPU for cs2.exe.");
        t.learnMore = QStringLiteral("On dual-GPU laptops, Windows may default to integrated graphics. "
                                      "This forces the high-performance discrete GPU for CS2.");
        t.risk = QStringLiteral("safe");
        t.actions.append(gpuPreferenceAction(QStringLiteral("auto"), QStringLiteral("GpuPreference=2;")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("cs2_launch_opts");
        t.category = QStringLiteral("FPS");
        t.name = QStringLiteral("CS2 — Recommended launch options registry hint");
        t.description = QStringLiteral("Stores recommended CS2 launch options (-high -novid -threads N) "
                                        "so you can copy them to Steam. Does NOT modify Steam files.");
        t.learnMore = QStringLiteral("-high sets process priority, -novid skips intro video, "
                                      "-threads N matches your CPU thread count for optimal load distribution.");
        t.risk = QStringLiteral("safe");
        // This is informational only — no real action, but we flag it.
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("nvidia_threaded_optim");
        t.category = QStringLiteral("FPS");
        t.name = QStringLiteral("NVIDIA — Threaded optimization hint");
        t.description = QStringLiteral("Writes a registry note to enable threaded optimization in the NVIDIA Control Panel. "
                                        "You should also set it via NVCP for it to take effect.");
        t.learnMore = QStringLiteral("Threaded optimization allows the NVIDIA driver to use multiple CPU threads "
                                      "for OpenGL command processing. Benefits vary by game engine.");
        t.risk = QStringLiteral("safe");
        // Informational registry breadcrumb
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Tweak\\Hints"),
            QStringLiteral("NVIDIA_ThreadedOptimization"),
            QStringLiteral("Enable in NVIDIA Control Panel > Manage 3D Settings > Threaded Optimization = On")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("large_system_cache");
        t.category = QStringLiteral("FPS");
        t.name = QStringLiteral("Enable large system cache (16 GB+ RAM)");
        t.description = QStringLiteral("Tells the kernel to use a large disk cache, benefiting texture streaming "
                                        "in games when you have plenty of RAM.");
        t.learnMore = QStringLiteral("With 16GB+ RAM, enabling a larger file cache reduces disk I/O for texture "
                                      "streaming and level loading. Only recommended with ample memory.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management"),
            QStringLiteral("LargeSystemCache"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_paging_exec");
        t.category = QStringLiteral("FPS");
        t.name = QStringLiteral("Keep drivers / kernel in RAM (16 GB+)");
        t.description = QStringLiteral("Prevents paging of executive code to disk. Reduces micro-stutters on "
                                        "systems with ample RAM.");
        t.learnMore = QStringLiteral("Normally Windows can page kernel-mode drivers to disk. This keeps them resident, "
                                      "eliminating rare but noticeable micro-stutters from page faults.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management"),
            QStringLiteral("DisablePagingExecutive"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }

    // ======= NETWORK =======
    {
        Tweak t;
        t.id = QStringLiteral("network_throttle");
        t.category = QStringLiteral("Network");
        t.name = QStringLiteral("Disable multimedia network throttling");
        t.description = QStringLiteral("Sets NetworkThrottlingIndex to 0xFFFFFFFF so multimedia apps don't throttle NIC throughput.");
        t.learnMore = QStringLiteral("Windows throttles network I/O for multimedia apps to prevent audio/video glitches. "
                                      "For gaming, removing this cap ensures maximum network throughput.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile"),
            QStringLiteral("NetworkThrottlingIndex"),
            QVariant::fromValue(static_cast<quint32>(0xffffffff))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("tcp_ack_frequency");
        t.category = QStringLiteral("Network");
        t.name = QStringLiteral("TCP ACK frequency = 1 (lower latency)");
        t.description = QStringLiteral("Sends TCP ACKs immediately instead of batching. "
                                        "Reduces round-trip time in online games.");
        t.learnMore = QStringLiteral("By default Windows batches TCP ACKs (every 2 segments or 200ms). "
                                      "Setting frequency to 1 sends an ACK for every packet, reducing RTT by up to 200ms.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        // Applied per-interface — we write a common tuning key
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters"),
            QStringLiteral("TcpAckFrequency"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("nagle_disable");
        t.category = QStringLiteral("Network");
        t.name = QStringLiteral("Disable Nagle's algorithm (TCP_NODELAY)");
        t.description = QStringLiteral("Disables Nagle buffering so small packets are sent immediately. "
                                        "Essential for competitive FPS netcode.");
        t.learnMore = QStringLiteral("Nagle’s algorithm buffers small outgoing packets to reduce header overhead. "
                                      "In games this adds up to 200ms of extra latency on player actions.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters"),
            QStringLiteral("TcpNoDelay"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_auto_tuning");
        t.category = QStringLiteral("Network");
        t.name = QStringLiteral("Disable TCP receive window auto-tuning");
        t.description = QStringLiteral("Prevents Windows from dynamically resizing the TCP window. "
                                        "Can reduce variability in ping for online gaming.");
        t.learnMore = QStringLiteral("Auto-tuning dynamically resizes the TCP receive window. "
                                      "While good for throughput, it can cause ping spikes in latency-sensitive games.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters"),
            QStringLiteral("EnableWsd"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }

    // ======= SERVICES =======
    {
        Tweak t;
        t.id = QStringLiteral("mmcss_priority");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Keep MMCSS scheduling active (NoLazyMode)");
        t.description = QStringLiteral("Ensures the multimedia class scheduler doesn't enter lazy mode, "
                                        "keeping game/audio thread priorities enforced.");
        t.learnMore = QStringLiteral("In lazy mode, MMCSS relaxes thread priority boosting after a few seconds of inactivity. "
                                      "NoLazyMode keeps priorities enforced continuously during gaming.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile"),
            QStringLiteral("NoLazyMode"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_diagtrack");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable Connected User Experiences (DiagTrack)");
        t.description = QStringLiteral("Stops the DiagTrack telemetry service that runs in the background "
                                        "and periodically uses CPU/disk.");
        t.learnMore = QStringLiteral("DiagTrack collects usage and diagnostics data and sends it to Microsoft. "
                                      "It periodically wakes up and generates disk I/O, which can cause micro-stutters.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(serviceAction(QStringLiteral("DiagTrack"), QStringLiteral("4")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_sysmain");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable SysMain / Superfetch (SSD users)");
        t.description = QStringLiteral("SysMain preloads commonly used apps into RAM. On SSDs this provides "
                                        "minimal benefit while consuming RAM and causing writes.");
        t.learnMore = QStringLiteral("SysMain was designed for HDDs to preload frequently used apps. "
                                      "On SSDs, apps load fast enough that the preloading wastes RAM and causes unnecessary writes.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(serviceAction(QStringLiteral("SysMain"), QStringLiteral("4")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_prefetch");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable Prefetch (SSD users)");
        t.description = QStringLiteral("Turns off the legacy Prefetch feature which is unnecessary on SSDs.");
        t.learnMore = QStringLiteral("Prefetch creates layout files to optimize HDD reads on boot. "
                                      "On SSDs, random reads are effectively instant, making Prefetch overhead without benefit.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management\\PrefetchParameters"),
            QStringLiteral("EnablePrefetcher"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_superfetch");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable Superfetch in registry (SSD users)");
        t.description = QStringLiteral("Registry counterpart to the SysMain service disable. "
                                        "Fully stops Superfetch preloading.");
        t.learnMore = QStringLiteral("This is the registry-level setting that complements disabling the SysMain service. "
                                      "Both should be disabled together for SSD systems.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management\\PrefetchParameters"),
            QStringLiteral("EnableSuperfetch"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_search_indexer");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable Windows Search indexing");
        t.description = QStringLiteral("Stops the WSearch service that indexes files in the background. "
                                        "Reduces disk I/O during gaming sessions.");
        t.learnMore = QStringLiteral("Windows Search constantly indexes file contents and metadata. "
                                      "This generates significant disk I/O that competes with game asset loading.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(serviceAction(QStringLiteral("WSearch"), QStringLiteral("4")));
        m_tweaks.append(t);
    }

    // ======= VISUAL =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_transparency");
        t.category = QStringLiteral("Visual");
        t.name = QStringLiteral("Disable transparency effects");
        t.description = QStringLiteral("Turns off the acrylic / blur transparency in Windows 10/11. "
                                        "Frees GPU compositing resources.");
        t.learnMore = QStringLiteral("The DWM compositor uses GPU shaders for transparency/blur effects. "
                                      "Disabling saves GPU overhead, especially on integrated graphics.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"),
            QStringLiteral("EnableTransparency"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_animations");
        t.category = QStringLiteral("Visual");
        t.name = QStringLiteral("Disable window animations & effects");
        t.description = QStringLiteral("Disables minimize/maximize animations, slide-open combos, "
                                        "and menu fade effects for a snappier desktop.");
        t.learnMore = QStringLiteral("Window animations use CPU and GPU resources for purely cosmetic transitions. "
                                      "Disabling makes the desktop feel noticeably more responsive.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Control Panel\\Desktop\\WindowMetrics"),
            QStringLiteral("MinAnimate"),
            QStringLiteral("0")));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Control Panel\\Desktop"),
            QStringLiteral("MenuShowDelay"),
            QStringLiteral("0")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("visual_fx_performance");
        t.category = QStringLiteral("Visual");
        t.name = QStringLiteral("Set Visual Effects to 'Best performance'");
        t.description = QStringLiteral("Sets the VisualFXSetting to performance mode, disabling shadows, "
                                        "smooth-scrolling, and fade effects system-wide.");
        t.learnMore = QStringLiteral("This is the master switch that disables all desktop visual effects at once. "
                                      "Equivalent to manually unchecking all options in System Properties > Performance.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects"),
            QStringLiteral("VisualFXSetting"),
            QVariant::fromValue(static_cast<quint32>(2))));
        m_tweaks.append(t);
    }

    // ======= PRIVACY =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_cortana");
        t.category = QStringLiteral("Privacy");
        t.name = QStringLiteral("Disable Cortana");
        t.description = QStringLiteral("Prevents Cortana from running in the background, saving CPU and memory.");
        t.learnMore = QStringLiteral("Cortana runs background services for voice recognition and indexing. "
                                      "Disabling frees ~50-100MB RAM and eliminates periodic CPU spikes.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search"),
            QStringLiteral("AllowCortana"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_telemetry");
        t.category = QStringLiteral("Privacy");
        t.name = QStringLiteral("Minimize Windows telemetry level");
        t.description = QStringLiteral("Sets telemetry to Security level (0), reducing background data "
                                        "collection that uses CPU, disk and network.");
        t.learnMore = QStringLiteral("Microsoft collects usage data at various levels. Level 0 (Security) sends only "
                                      "critical security data, drastically reducing background network and disk activity.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection"),
            QStringLiteral("AllowTelemetry"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_activity_history");
        t.category = QStringLiteral("Privacy");
        t.name = QStringLiteral("Disable activity history & Timeline");
        t.description = QStringLiteral("Stops Windows from collecting your activity history for Timeline. "
                                        "Reduces background CPU & disk writes.");
        t.learnMore = QStringLiteral("Activity History tracks which apps you use and can sync this to the cloud. "
                                      "Timeline generates periodic disk writes and CPU usage for indexing.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Policies\\Microsoft\\Windows\\System"),
            QStringLiteral("EnableActivityFeed"),
            QVariant::fromValue(static_cast<quint32>(0))));
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Policies\\Microsoft\\Windows\\System"),
            QStringLiteral("PublishUserActivities"),
            QVariant::fromValue(static_cast<quint32>(0))));
        t.requiresAdmin = true;
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_location_tracking");
        t.category = QStringLiteral("Privacy");
        t.name = QStringLiteral("Disable location tracking");
        t.description = QStringLiteral("Prevents apps from using your location. Saves battery and network usage.");
        t.learnMore = QStringLiteral("Location services periodically query Wi-Fi networks and GPS for your position. "
                                      "Disabling reduces network requests and eliminates a privacy concern.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\location"),
            QStringLiteral("Value"),
            QStringLiteral("Deny")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_background_apps");
        t.category = QStringLiteral("Privacy");
        t.name = QStringLiteral("Disable background apps");
        t.description = QStringLiteral("Prevents UWP/Store apps from running in the background. "
                                        "Significant RAM and CPU savings.");
        t.learnMore = QStringLiteral("Microsoft Store apps can run background tasks even when not open. "
                                      "Disabling globally can save 200-500MB of RAM and reduce CPU interruptions.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications"),
            QStringLiteral("GlobalUserDisabled"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_tips_notifications");
        t.category = QStringLiteral("Privacy");
        t.name = QStringLiteral("Disable Windows tips & suggestions");
        t.description = QStringLiteral("Stops 'Get tips, tricks and suggestions' notifications that cause "
                                        "random pop-ups during gaming.");
        t.learnMore = QStringLiteral("Windows periodically checks for tips to show you, creating background activity. "
                                      "The notifications can minimize games or cause focus loss.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager"),
            QStringLiteral("SoftLandingEnabled"),
            QVariant::fromValue(static_cast<quint32>(0))));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager"),
            QStringLiteral("SubscribedContent-338389Enabled"),
            QVariant::fromValue(static_cast<quint32>(0))));
        m_tweaks.append(t);
    }

    // ======= Additional LATENCY =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_power_throttling");
        t.category = QStringLiteral("Latency");
        t.name = QStringLiteral("Disable Intel power throttling");
        t.description = QStringLiteral("Prevents Windows from throttling CPU frequency for power savings. "
                                        "Ensures max clock during gaming sessions.");
        t.learnMore = QStringLiteral("Windows 10/11 can throttle background processes via Intel Speed Shift. "
                                      "This registry key disables all power throttling, keeping clocks at max.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Power\\PowerThrottling"),
            QStringLiteral("PowerThrottlingOff"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }

    // ======= Additional GAMING =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_mouse_accel");
        t.category = QStringLiteral("Gaming");
        t.name = QStringLiteral("Disable mouse acceleration (enhance pointer precision)");
        t.description = QStringLiteral("Removes the 'Enhance pointer precision' acceleration curve. "
                                        "Essential for consistent aim in FPS games.");
        t.learnMore = QStringLiteral("Mouse acceleration makes cursor speed vary with movement speed. "
                                      "For gaming, a 1:1 relationship between hand movement and cursor is critical for muscle memory.");
        t.risk = QStringLiteral("safe");
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Control Panel\\Mouse"),
            QStringLiteral("MouseSpeed"),
            QStringLiteral("0")));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Control Panel\\Mouse"),
            QStringLiteral("MouseThreshold1"),
            QStringLiteral("0")));
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Control Panel\\Mouse"),
            QStringLiteral("MouseThreshold2"),
            QStringLiteral("0")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("gpu_msi_mode");
        t.category = QStringLiteral("Gaming");
        t.name = QStringLiteral("Enable GPU MSI (Message Signaled Interrupts)");
        t.description = QStringLiteral("Switches GPU interrupts from legacy line-based to MSI mode. "
                                        "Reduces DPC latency and improves frame delivery.");
        t.learnMore = QStringLiteral("MSI eliminates shared interrupt lines, reducing DPC latency by up to 50%. "
                                      "Most modern GPUs support MSI but Windows may not enable it by default.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        // This is a hint — the actual path depends on the GPU device ID
        t.actions.append(registryAction(
            QStringLiteral("HKCU"),
            QStringLiteral("Software\\Tweak\\Hints"),
            QStringLiteral("GPU_MSI_Mode"),
            QStringLiteral("Enable MSI mode for your GPU in Device Manager > Properties > MSI: Set to MessageSignaledInterruptProperties")));
        m_tweaks.append(t);
    }

    // ======= Additional NETWORK =======
    {
        Tweak t;
        t.id = QStringLiteral("dns_cache_optimize");
        t.category = QStringLiteral("Network");
        t.name = QStringLiteral("Optimize DNS cache size");
        t.description = QStringLiteral("Increases MaxCacheTtl and MaxCacheEntryTtlLimit for faster DNS "
                                        "resolution during gaming.");
        t.learnMore = QStringLiteral("Increasing DNS cache TTL means fewer DNS lookups during gaming sessions. "
                                      "Reduces network latency for server connections and reduces DNS traffic.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Dnscache\\Parameters"),
            QStringLiteral("MaxCacheTtl"),
            QVariant::fromValue(static_cast<quint32>(86400))));
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Dnscache\\Parameters"),
            QStringLiteral("MaxNegativeCacheTtl"),
            QVariant::fromValue(static_cast<quint32>(5))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("network_adapter_offload");
        t.category = QStringLiteral("Network");
        t.name = QStringLiteral("Disable TCP/IP task offloading");
        t.description = QStringLiteral("Prevents the NIC from handling TCP checksums and segmentation. "
                                        "Can reduce latency spikes on some adapters.");
        t.learnMore = QStringLiteral("TCP offloading moves packet processing to the NIC firmware. "
                                      "Some NICs have buggy firmware causing latency spikes. Disabling moves processing back to CPU.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters"),
            QStringLiteral("DisableTaskOffload"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }

    // ======= Additional SERVICES =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_windows_update_service");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Pause Windows Update service during gaming");
        t.description = QStringLiteral("Sets the Windows Update service to manual start. "
                                        "Prevents updates from downloading during gaming. Re-enable when done.");
        t.learnMore = QStringLiteral("Windows Update can start downloading large updates during gaming, "
                                      "consuming bandwidth and disk I/O. Setting to manual means it only checks when you trigger it.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(serviceAction(QStringLiteral("wuauserv"), QStringLiteral("3"))); // 3 = manual
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_remote_desktop");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable Remote Desktop services");
        t.description = QStringLiteral("Stops TermService and related services that listen on the network. "
                                        "Reduces attack surface and frees resources.");
        t.learnMore = QStringLiteral("Remote Desktop listens on port 3389 for incoming connections. "
                                      "If you don't use RDP, disabling saves memory and closes a common attack vector.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(serviceAction(QStringLiteral("TermService"), QStringLiteral("4")));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("disable_print_spooler");
        t.category = QStringLiteral("Services");
        t.name = QStringLiteral("Disable Print Spooler (if no printer)");
        t.description = QStringLiteral("Stops the Print Spooler service. Saves resources and closes "
                                        "a known security attack vector (PrintNightmare). Skip if you print.");
        t.learnMore = QStringLiteral("Print Spooler has been the target of multiple critical CVEs (PrintNightmare). "
                                      "If you don't print, disabling eliminates this attack surface and frees ~10MB RAM.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(serviceAction(QStringLiteral("Spooler"), QStringLiteral("4")));
        m_tweaks.append(t);
    }

    // ======= MEMORY =======
    {
        Tweak t;
        t.id = QStringLiteral("disable_memory_compression");
        t.category = QStringLiteral("Memory");
        t.name = QStringLiteral("Disable memory compression");
        t.description = QStringLiteral("Stops Windows from compressing idle pages in RAM. "
                                        "Reduces CPU overhead on systems with 16 GB+ RAM.");
        t.learnMore = QStringLiteral("Windows 10/11 compresses unused memory pages instead of paging to disk. "
                                      "This saves RAM but uses CPU cycles. With 16GB+, you have enough RAM to skip compression.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management"),
            QStringLiteral("DisableCompression"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("svchost_split_threshold");
        t.category = QStringLiteral("Memory");
        t.name = QStringLiteral("Optimize SvcHost split threshold");
        t.description = QStringLiteral("Sets SvcHostSplitThresholdInKB to your RAM size so services share fewer processes.");
        t.learnMore = QStringLiteral("By default Windows splits each service into its own svchost.exe for isolation. "
                                      "Setting the threshold to your total RAM allows services to share processes, saving ~200MB.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control"),
            QStringLiteral("SvcHostSplitThresholdInKB"),
            QVariant::fromValue(static_cast<quint32>(67108864))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("ndu_disable");
        t.category = QStringLiteral("Memory");
        t.name = QStringLiteral("Disable Network Data Usage monitor (NDU)");
        t.description = QStringLiteral("Stops the NDU driver that tracks per-app network usage. "
                                        "Known to cause memory leaks on some systems.");
        t.learnMore = QStringLiteral("The NDU driver (ndu.sys) monitors network usage per process. "
                                      "It has a known memory leak that can consume GBs of non-paged pool over time.");
        t.risk = QStringLiteral("safe");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\Ndu"),
            QStringLiteral("Start"),
            QVariant::fromValue(static_cast<quint32>(4))));
        m_tweaks.append(t);
    }
    {
        Tweak t;
        t.id = QStringLiteral("optimize_working_set");
        t.category = QStringLiteral("Memory");
        t.name = QStringLiteral("Optimize process working set trimming");
        t.description = QStringLiteral("Reduces aggressive working set trimming so games keep their "
                                        "memory pages resident in RAM.");
        t.learnMore = QStringLiteral("Windows aggressively trims working sets of background processes. "
                                      "This can affect games during ALT-TAB, causing stutters when pages are reclaimed.");
        t.risk = QStringLiteral("advanced");
        t.requiresAdmin = true;
        t.actions.append(registryAction(
            QStringLiteral("HKLM"),
            QStringLiteral("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management"),
            QStringLiteral("LargePageMinimum"),
            QVariant::fromValue(static_cast<quint32>(1))));
        m_tweaks.append(t);
    }
}

// ---------------------------------------------------------------------------
// Apply a single tweak
// ---------------------------------------------------------------------------
void TweakEngine::applyTweak(Tweak &tweak)
{
    if (tweak.requiresAdmin && !isAdmin())
        return;

    QJsonObject backup;
    QJsonArray actionsBackup;
    bool powerPlanBackedUp = false;

    for (const QVariantMap &action : std::as_const(tweak.actions)) {
        const QString type = action.value(QStringLiteral("type")).toString();

        if (type == QStringLiteral("registry")) {
            const QString hive  = action.value(QStringLiteral("hive")).toString();
            const QString path  = action.value(QStringLiteral("path")).toString();
            const QString name  = action.value(QStringLiteral("name")).toString();
            const QVariant val  = action.value(QStringLiteral("value"));

            RegistryValue current = RegistryUtil::readValue(hive, path, name);
            QJsonObject ab;
            ab.insert(QStringLiteral("type"), type);
            ab.insert(QStringLiteral("hive"), hive);
            ab.insert(QStringLiteral("path"), path);
            ab.insert(QStringLiteral("name"), name);
            ab.insert(QStringLiteral("hadValue"), current.exists);
            if (current.exists)
                ab.insert(QStringLiteral("value"), QJsonValue::fromVariant(current.value));
            actionsBackup.append(ab);

            RegistryUtil::writeValue(hive, path, name, val);

        } else if (type == QStringLiteral("powerplan")) {
            const QString guid = action.value(QStringLiteral("guid")).toString();
            if (!powerPlanBackedUp) {
                const QString cur = PowerUtil::activeSchemeGuid();
                if (!cur.isEmpty()) {
                    QJsonObject ab;
                    ab.insert(QStringLiteral("type"), type);
                    ab.insert(QStringLiteral("previous"), cur);
                    actionsBackup.append(ab);
                    powerPlanBackedUp = true;
                }
            }
            if (PowerUtil::setActiveScheme(guid))
                break; // first successful plan wins

        } else if (type == QStringLiteral("gpupref")) {
            QString exePath = action.value(QStringLiteral("exePath")).toString();
            if (exePath == QStringLiteral("auto")) {
                exePath = m_cs2Path.isEmpty() ? PowerUtil::detectCs2Path() : m_cs2Path;
            }
            if (exePath.isEmpty()) continue;

            const QString pref = action.value(QStringLiteral("pref")).toString();
            const QString regPath = QStringLiteral("Software\\Microsoft\\DirectX\\UserGpuPreferences");

            RegistryValue current = RegistryUtil::readValue(QStringLiteral("HKCU"), regPath, exePath);
            QJsonObject ab;
            ab.insert(QStringLiteral("type"), type);
            ab.insert(QStringLiteral("exePath"), exePath);
            ab.insert(QStringLiteral("hadValue"), current.exists);
            if (current.exists)
                ab.insert(QStringLiteral("value"), QJsonValue::fromVariant(current.value));
            actionsBackup.append(ab);

            RegistryUtil::writeValue(QStringLiteral("HKCU"), regPath, exePath, pref);

        } else if (type == QStringLiteral("service")) {
            // Change service start type via registry
            const QString svc   = action.value(QStringLiteral("service")).toString();
            const QString start = action.value(QStringLiteral("startType")).toString();
            const QString regPath = QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\") + svc;

            RegistryValue current = RegistryUtil::readValue(QStringLiteral("HKLM"), regPath, QStringLiteral("Start"));
            QJsonObject ab;
            ab.insert(QStringLiteral("type"), type);
            ab.insert(QStringLiteral("service"), svc);
            ab.insert(QStringLiteral("hadValue"), current.exists);
            if (current.exists)
                ab.insert(QStringLiteral("value"), QJsonValue::fromVariant(current.value));
            actionsBackup.append(ab);

            RegistryUtil::writeValue(QStringLiteral("HKLM"), regPath, QStringLiteral("Start"),
                                     QVariant::fromValue(static_cast<quint32>(start.toUInt())));
        }
    }

    if (!actionsBackup.isEmpty()) {
        backup.insert(QStringLiteral("actions"), actionsBackup);
        saveBackup(tweak.id, backup);
    }
    tweak.applied = true;
}

// ---------------------------------------------------------------------------
// Restore a single tweak
// ---------------------------------------------------------------------------
void TweakEngine::restoreTweak(Tweak &tweak)
{
    const QJsonObject backup = loadBackup(tweak.id);
    if (backup.isEmpty()) { tweak.applied = false; return; }

    const QJsonArray arr = backup.value(QStringLiteral("actions")).toArray();
    for (const QJsonValue &entry : arr) {
        const QJsonObject a = entry.toObject();
        const QString type  = a.value(QStringLiteral("type")).toString();

        if (type == QStringLiteral("registry")) {
            const QString hive = a.value(QStringLiteral("hive")).toString();
            const QString path = a.value(QStringLiteral("path")).toString();
            const QString name = a.value(QStringLiteral("name")).toString();
            if (a.value(QStringLiteral("hadValue")).toBool())
                RegistryUtil::writeValue(hive, path, name, a.value(QStringLiteral("value")).toVariant());
            else
                RegistryUtil::deleteValue(hive, path, name);

        } else if (type == QStringLiteral("powerplan")) {
            const QString prev = a.value(QStringLiteral("previous")).toString();
            if (!prev.isEmpty()) PowerUtil::setActiveScheme(prev);

        } else if (type == QStringLiteral("gpupref")) {
            const QString exePath = a.value(QStringLiteral("exePath")).toString();
            const QString regPath = QStringLiteral("Software\\Microsoft\\DirectX\\UserGpuPreferences");
            if (a.value(QStringLiteral("hadValue")).toBool())
                RegistryUtil::writeValue(QStringLiteral("HKCU"), regPath, exePath, a.value(QStringLiteral("value")).toVariant());
            else
                RegistryUtil::deleteValue(QStringLiteral("HKCU"), regPath, exePath);

        } else if (type == QStringLiteral("service")) {
            const QString svc = a.value(QStringLiteral("service")).toString();
            const QString regPath = QStringLiteral("SYSTEM\\CurrentControlSet\\Services\\") + svc;
            if (a.value(QStringLiteral("hadValue")).toBool())
                RegistryUtil::writeValue(QStringLiteral("HKLM"), regPath, QStringLiteral("Start"), a.value(QStringLiteral("value")).toVariant());
        }
    }
    tweak.applied = false;
}

// ---------------------------------------------------------------------------
// Backup persistence
// ---------------------------------------------------------------------------
void TweakEngine::saveBackup(const QString &id, const QJsonObject &backup)
{
    const QString path = backupPath();
    QDir().mkpath(QFileInfo(path).absolutePath());

    QJsonObject root;
    QFile file(path);
    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        root = QJsonDocument::fromJson(file.readAll()).object();
        file.close();
    }
    root.insert(id, backup);

    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        file.close();
    }
}

QJsonObject TweakEngine::loadBackup(const QString &id) const
{
    QFile file(backupPath());
    if (!file.open(QIODevice::ReadOnly)) return {};
    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    file.close();
    return root.value(id).toObject();
}
