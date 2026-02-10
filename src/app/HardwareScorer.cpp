#include "app/HardwareScorer.h"
#include <algorithm>

HardwareScorer::HardwareScorer(QObject *parent)
    : QObject(parent)
{
}

// ─── Internal hardware databases ───────────────────────────────────────

struct GpuEntry { const char *keyword; int score; };
struct CpuEntry { const char *keyword; int score; };

static const GpuEntry gpuDb[] = {
    // NVIDIA — high end
    {"RTX 4090", 98}, {"RTX 4080", 94}, {"RTX 4070 Ti Super", 90},
    {"RTX 4070 Ti", 88}, {"RTX 4070 Super", 86}, {"RTX 4070", 83},
    {"RTX 4060 Ti", 78}, {"RTX 4060", 72}, {"RTX 3090 Ti", 93},
    {"RTX 3090", 91}, {"RTX 3080 Ti", 89}, {"RTX 3080", 86},
    {"RTX 3070 Ti", 82}, {"RTX 3070", 79}, {"RTX 3060 Ti", 75},
    {"RTX 3060", 68}, {"RTX 3050", 55}, {"RTX 2080 Ti", 82},
    {"RTX 2080 Super", 79}, {"RTX 2080", 77}, {"RTX 2070 Super", 74},
    {"RTX 2070", 71}, {"RTX 2060 Super", 68}, {"RTX 2060", 64},
    {"GTX 1080 Ti", 70}, {"GTX 1080", 64}, {"GTX 1070 Ti", 61},
    {"GTX 1070", 58}, {"GTX 1060", 45}, {"GTX 1050 Ti", 35},
    {"GTX 1050", 30}, {"GTX 1660 Ti", 55}, {"GTX 1660 Super", 54},
    {"GTX 1660", 50}, {"GTX 1650 Super", 42}, {"GTX 1650", 35},
    // AMD
    {"RX 7900 XTX", 96}, {"RX 7900 XT", 92}, {"RX 7800 XT", 85},
    {"RX 7700 XT", 80}, {"RX 7600", 68}, {"RX 6950 XT", 90},
    {"RX 6900 XT", 88}, {"RX 6800 XT", 84}, {"RX 6800", 80},
    {"RX 6750 XT", 73}, {"RX 6700 XT", 70}, {"RX 6650 XT", 63},
    {"RX 6600 XT", 60}, {"RX 6600", 55}, {"RX 6500 XT", 35},
    {"RX 5700 XT", 66}, {"RX 5700", 62}, {"RX 5600 XT", 58},
    {"RX 580", 40}, {"RX 570", 35},
    // Intel
    {"Arc A770", 65}, {"Arc A750", 60}, {"Arc A580", 50},
    {"Arc A380", 30},
    // Integrated
    {"Iris Xe", 20}, {"UHD 770", 15}, {"UHD 730", 12},
    {"UHD 630", 10}, {"UHD 620", 8}, {"Vega 8", 15}, {"Vega 11", 18},
    {"Radeon 780M", 28}, {"Radeon 760M", 24}, {"Radeon 680M", 22},
};

static const CpuEntry cpuDb[] = {
    // Intel — 14th gen
    {"14900K", 97}, {"14700K", 92}, {"14600K", 86}, {"14400F", 78},
    {"14100F", 62},
    // Intel — 13th gen
    {"13900K", 95}, {"13700K", 89}, {"13600K", 84}, {"13400F", 75},
    {"13100F", 58},
    // Intel — 12th gen
    {"12900K", 90}, {"12700K", 85}, {"12600K", 80}, {"12400F", 72},
    {"12100F", 56},
    // Intel — older
    {"11900K", 78}, {"11700K", 75}, {"11600K", 70}, {"11400F", 65},
    {"10900K", 76}, {"10700K", 72}, {"10600K", 66}, {"10400F", 60},
    {"9900K", 70}, {"9700K", 65}, {"9600K", 58}, {"9400F", 52},
    // AMD — 7000 series
    {"7950X3D", 98}, {"7950X", 96}, {"7900X3D", 95}, {"7900X", 93},
    {"7800X3D", 94}, {"7700X", 88}, {"7600X", 82}, {"7600", 79},
    // AMD — 5000 series
    {"5950X", 90}, {"5900X", 87}, {"5800X3D", 91}, {"5800X", 83},
    {"5700X", 80}, {"5600X", 76}, {"5600", 73}, {"5500", 68},
    // AMD — 3000 series
    {"3950X", 80}, {"3900X", 77}, {"3800X", 73}, {"3700X", 70},
    {"3600", 62}, {"3500X", 55}, {"3300X", 52}, {"3100", 48},
};

// ─── Public ────────────────────────────────────────────────────────────

void HardwareScorer::score(const HardwareInfo &hw)
{
    m_cpuScore     = scoreCpu(hw);
    m_gpuScore     = scoreGpu(hw);
    m_ramScore     = scoreRam(hw);
    m_storageScore = scoreStorage(hw);

    m_gamingScore      = static_cast<int>(m_gpuScore * 0.45 + m_cpuScore * 0.35
                                        + m_ramScore * 0.10 + m_storageScore * 0.10);
    m_performanceScore = static_cast<int>(m_cpuScore * 0.35 + m_gpuScore * 0.25
                                        + m_ramScore * 0.20 + m_storageScore * 0.20);

    m_tier       = classifyTier(m_gamingScore);
    m_bottleneck = detectBottleneck();
    m_insights   = generateInsights(hw);

    emit scored();
}

// ─── Private scoring ───────────────────────────────────────────────────

int HardwareScorer::scoreCpu(const HardwareInfo &hw) const
{
    const QString name = hw.cpuName.toUpper();
    int best = 0;
    for (const auto &e : cpuDb) {
        if (name.contains(QString::fromLatin1(e.keyword).toUpper())) {
            best = std::max(best, e.score);
        }
    }
    if (best == 0) {
        // Heuristic fallback based on core/thread count + clock
        int base = std::min(hw.cpuCores * 5, 60);
        if (hw.cpuMaxClockMhz > 4500) base += 20;
        else if (hw.cpuMaxClockMhz > 3500) base += 10;
        if (hw.cpuThreads > hw.cpuCores) base += 10; // has HT/SMT
        best = std::clamp(base, 15, 80);
    }
    return std::clamp(best, 0, 100);
}

int HardwareScorer::scoreGpu(const HardwareInfo &hw) const
{
    const QString name = hw.gpuName.toUpper();
    int best = 0;
    for (const auto &e : gpuDb) {
        if (name.contains(QString::fromLatin1(e.keyword).toUpper())) {
            best = std::max(best, e.score);
        }
    }
    if (best == 0) {
        // Fallback: integrated ≈ 10, unknown discrete ≈ 40
        if (hw.gpuVendor == "Intel" || hw.gpuName.contains("Vega", Qt::CaseInsensitive)
            || hw.gpuName.contains("Iris", Qt::CaseInsensitive)
            || hw.gpuName.contains("UHD", Qt::CaseInsensitive)) {
            best = 12;
        } else {
            best = 40;
        }
    }
    return std::clamp(best, 0, 100);
}

int HardwareScorer::scoreRam(const HardwareInfo &hw) const
{
    const double gb = hw.ramMb / 1024.0;
    if (gb >= 64) return 95;
    if (gb >= 32) return 85;
    if (gb >= 16) return 70;
    if (gb >= 12) return 55;
    if (gb >= 8)  return 40;
    if (gb >= 4)  return 20;
    return 10;
}

int HardwareScorer::scoreStorage(const HardwareInfo &hw) const
{
    if (hw.hasNvme) return 95;
    if (hw.hasSsd)  return 70;
    return 30; // HDD
}

QString HardwareScorer::classifyTier(int overall) const
{
    if (overall >= 85) return QStringLiteral("Ultra");
    if (overall >= 70) return QStringLiteral("High-End");
    if (overall >= 55) return QStringLiteral("Mid-Range");
    if (overall >= 35) return QStringLiteral("Entry");
    return QStringLiteral("Low-End");
}

QString HardwareScorer::detectBottleneck() const
{
    int minScore = std::min({m_cpuScore, m_gpuScore, m_ramScore, m_storageScore});
    int maxScore = std::max({m_cpuScore, m_gpuScore, m_ramScore, m_storageScore});

    if (maxScore - minScore < 15)
        return QStringLiteral("Balanced — no significant bottleneck");

    if (minScore == m_cpuScore)
        return QStringLiteral("CPU is the bottleneck — consider upgrading processor");
    if (minScore == m_gpuScore)
        return QStringLiteral("GPU is the bottleneck — consider upgrading graphics card");
    if (minScore == m_ramScore)
        return QStringLiteral("RAM is the bottleneck — consider adding more memory");
    return QStringLiteral("Storage is the bottleneck — consider upgrading to NVMe SSD");
}

QVariantList HardwareScorer::generateInsights(const HardwareInfo &hw) const
{
    QVariantList list;

    auto addInsight = [&](const QString &icon, const QString &title, const QString &desc, const QString &severity) {
        QVariantMap m;
        m["icon"] = icon;
        m["title"] = title;
        m["description"] = desc;
        m["severity"] = severity; // "good", "warning", "critical"
        list.append(m);
    };

    // CPU insights
    if (m_cpuScore >= 80)
        addInsight("🟢", "CPU Excellent", "Your processor is powerful enough for all modern games at max settings.", "good");
    else if (m_cpuScore >= 55)
        addInsight("🟡", "CPU Adequate", "Your processor handles most games well but may struggle in CPU-heavy titles.", "warning");
    else
        addInsight("🔴", "CPU Weak", "Your processor may cause significant frame drops in demanding games.", "critical");

    // GPU insights
    if (m_gpuScore >= 80)
        addInsight("🟢", "GPU Powerful", "Your graphics card can handle high/ultra settings in most games.", "good");
    else if (m_gpuScore >= 50)
        addInsight("🟡", "GPU Mid-Range", "Target medium-high settings for best FPS. Consider lowering shadows and AA.", "warning");
    else if (m_gpuScore >= 20)
        addInsight("🔴", "GPU Low", "You'll need to use low settings for playable FPS in modern titles.", "critical");
    else
        addInsight("🔴", "Integrated Graphics", "Gaming will be limited to lightweight titles. A dedicated GPU is strongly recommended.", "critical");

    // RAM
    double gb = hw.ramMb / 1024.0;
    if (gb >= 16)
        addInsight("🟢", "RAM Sufficient", QString::number(gb, 'f', 0) + " GB — no memory bottleneck expected.", "good");
    else if (gb >= 8)
        addInsight("🟡", "RAM Tight", QString::number(gb, 'f', 0) + " GB — close background apps while gaming for best performance.", "warning");
    else
        addInsight("🔴", "RAM Low", QString::number(gb, 'f', 0) + " GB — strongly consider upgrading to 16 GB.", "critical");

    // Storage
    if (hw.hasNvme)
        addInsight("🟢", "NVMe SSD", "Fast storage — minimal load times and no hitching.", "good");
    else if (hw.hasSsd)
        addInsight("🟡", "SATA SSD", "Good storage speed. NVMe would reduce load times further.", "warning");
    else
        addInsight("🔴", "HDD Detected", "Hard drive causes long load times and texture streaming issues. SSD upgrade highly recommended.", "critical");

    return list;
}
