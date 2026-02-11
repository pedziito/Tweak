#include "app/AppController.h"
#include "app/UacHelper.h"

#include <QCoreApplication>
#include <QProcess>
#include <QSysInfo>

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_detector()
    , m_hwInfo(m_detector.detect())
    , m_engine()
    , m_model(m_engine.tweaks(), this)
    , m_startupScanner()
    , m_settings(this)
    , m_benchmark(this)
    , m_systemMonitor(this)
    , m_scorer(this)
    , m_gameBenchmark(this)
    , m_configManager(this)
{
    // Restore persisted CS2 path
    const QString savedCs2 = m_settings.cs2Path();
    if (!savedCs2.isEmpty())
        m_engine.setCs2Path(savedCs2);

    m_engine.updateRecommendations(m_hwInfo);
    m_model.refresh();
    refreshStartupSuggestions();

    // Score hardware
    m_scorer.score(m_hwInfo);

    // Initialize game benchmark with hardware info
    m_gameBenchmark.setHardware(m_hwInfo, &m_scorer);

    // Start system monitor
    m_systemMonitor.start();

    // Connect benchmark signals
    connect(&m_benchmark, &BenchmarkEngine::resultsChanged, this, &AppController::benchmarkChanged);
    connect(&m_benchmark, &BenchmarkEngine::runningChanged, this, &AppController::benchmarkRunningChanged);
}

// ---------------------------------------------------------------------------
// Hardware getters
// ---------------------------------------------------------------------------
QString AppController::cpuName()        const { return m_hwInfo.cpuName; }
QString AppController::gpuName()        const { return m_hwInfo.gpuName; }
QString AppController::gpuVendor()      const { return m_hwInfo.gpuVendor; }
int     AppController::cpuCores()       const { return m_hwInfo.cpuCores; }
int     AppController::cpuThreads()     const { return m_hwInfo.cpuThreads; }
QString AppController::motherboardName()const { return m_hwInfo.motherboard; }
bool    AppController::hasSsd()         const { return m_hwInfo.hasSsd; }
bool    AppController::hasNvme()        const { return m_hwInfo.hasNvme; }

QString AppController::totalRam() const { return ramText(); }

QString AppController::ramText() const
{
    if (m_hwInfo.ramMb == 0) return QStringLiteral("Unknown");
    const double gb = static_cast<double>(m_hwInfo.ramMb) / 1024.0;
    return QString::number(gb, 'f', 1) + QStringLiteral(" GB");
}

QString AppController::storageText() const
{
    return m_hwInfo.storage.isEmpty()
               ? QStringLiteral("Unknown")
               : m_hwInfo.storage.join(QStringLiteral(", "));
}

QString AppController::diskModel() const
{
    return m_hwInfo.storage.isEmpty()
               ? QStringLiteral("Unknown")
               : m_hwInfo.storage.first();
}

QString AppController::osVersion() const
{
    return QSysInfo::prettyProductName();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
bool AppController::isAdmin()          const { return m_engine.isAdmin(); }
int  AppController::appliedCount()     const { return m_engine.appliedCount(); }
int  AppController::recommendedCount() const { return m_engine.recommendedCount(); }

TweakListModel *AppController::tweaksModel()       { return &m_model; }
QVariantList    AppController::startupSuggestions() const { return m_startupSuggestions; }
QStringList     AppController::categories()         const { return m_engine.categories(); }

// System Monitor
SystemMonitor *AppController::systemMonitor() { return &m_systemMonitor; }

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------
QString AppController::cs2Path() const        { return m_engine.cs2Path(); }
void    AppController::setCs2Path(const QString &path)
{
    m_engine.setCs2Path(path);
    m_settings.setCs2Path(path);
    emit cs2PathChanged();
}

QString AppController::selectedCategory() const        { return m_settings.selectedCategory(); }
void    AppController::setSelectedCategory(const QString &cat)
{
    m_settings.setSelectedCategory(cat);
    emit selectedCategoryChanged();
}

QString AppController::filterText() const { return m_filterText; }
void    AppController::setFilterText(const QString &text)
{
    if (m_filterText == text) return;
    m_filterText = text;
    emit filterTextChanged();
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------
void AppController::refreshHardware()
{
    m_hwInfo = m_detector.detect();
    m_engine.updateRecommendations(m_hwInfo);
    m_model.refresh();
    m_scorer.score(m_hwInfo);
    m_gameBenchmark.setHardware(m_hwInfo, &m_scorer);
    emit hardwareChanged();
    emit tweaksChanged();
}

void AppController::applyRecommended()
{
    m_engine.applyRecommended();
    m_model.refresh();
    emit tweaksChanged();
}

void AppController::restoreDefaults()
{
    m_engine.restoreDefaults();
    m_model.refresh();
    emit tweaksChanged();
}

void AppController::toggleTweak(int row)
{
    if (!m_model.isValidRow(row)) return;
    const QString id = m_model.tweakIdForRow(row);
    m_engine.toggleTweak(id);
    m_model.refreshRow(row);
    emit tweaksChanged();
}

bool AppController::requestAdmin()
{
    if (isAdmin()) return true;
    return UacHelper::relaunchAsAdmin();
}

void AppController::refreshStartupSuggestions()
{
    m_startupSuggestions = m_startupScanner.scan();
    emit startupChanged();
}

// New actions
void AppController::applyAllGaming()
{
    applyRecommended();
}

void AppController::restoreAll()
{
    restoreDefaults();
}

void AppController::clearTempFiles()
{
#ifdef Q_OS_WIN
    QProcess::startDetached("cmd", QStringList() << "/c" << "del /q /s %TEMP%\\* 2>nul");
#else
    QProcess::startDetached("sh", QStringList() << "-c" << "rm -rf /tmp/tweak_temp 2>/dev/null");
#endif
}

void AppController::flushDns()
{
#ifdef Q_OS_WIN
    QProcess::startDetached("cmd", QStringList() << "/c" << "ipconfig /flushdns");
#else
    QProcess::startDetached("sh", QStringList() << "-c" << "resolvectl flush-caches 2>/dev/null || systemd-resolve --flush-caches 2>/dev/null");
#endif
}

// ---------------------------------------------------------------------------
// Benchmark
// ---------------------------------------------------------------------------
QVariantList AppController::benchmarkResults() const     { return m_benchmark.results(); }
bool         AppController::benchmarkRunning() const     { return m_benchmark.running(); }
bool         AppController::benchmarkHasBaseline() const { return m_benchmark.hasBaseline(); }

void AppController::runBaseline()    { m_benchmark.runBaseline(); }
void AppController::runAfterTweaks() { m_benchmark.runAfterTweaks(); }
void AppController::resetBenchmark() { m_benchmark.reset(); }

// ---------------------------------------------------------------------------
// Hardware Scorer
// ---------------------------------------------------------------------------
HardwareScorer *AppController::hwScorer() { return &m_scorer; }

// ---------------------------------------------------------------------------
// Game Benchmark
// ---------------------------------------------------------------------------
GameBenchmark *AppController::gameBenchmark() { return &m_gameBenchmark; }

void AppController::runGameBenchmark()
{
    m_gameBenchmark.runEstimation();
}

// ---------------------------------------------------------------------------
// Config Manager
// ---------------------------------------------------------------------------
ConfigManager *AppController::configManager() { return &m_configManager; }

void AppController::saveConfiguration(const QString &name)
{
    m_configManager.saveConfig(name, appliedTweakIds());
}

QStringList AppController::loadConfiguration(const QString &name)
{
    const QStringList ids = m_configManager.loadConfig(name);
    // Restore defaults first, then apply the loaded config tweaks
    m_engine.restoreDefaults();
    for (const QString &id : ids) {
        m_engine.toggleTweak(id);
    }
    m_model.refresh();
    emit tweaksChanged();
    return ids;
}

void AppController::deleteConfiguration(const QString &name)
{
    m_configManager.deleteConfig(name);
}

QStringList AppController::appliedTweakIds() const
{
    QStringList ids;
    for (const Tweak &t : m_engine.tweaks()) {
        if (t.applied)
            ids.append(t.id);
    }
    return ids;
}

// ---------------------------------------------------------------------------
// Verification
// ---------------------------------------------------------------------------
bool AppController::verifyTweak(int row)
{
    if (!m_model.isValidRow(row)) return false;
    const QString id = m_model.tweakIdForRow(row);
    bool ok = m_engine.verifyTweak(id);
    m_model.refreshRow(row);
    return ok;
}

void AppController::verifyAllTweaks()
{
    m_engine.verifyAllTweaks();
    m_model.refresh();
    emit tweaksChanged();
}

void AppController::batchApplyTweaks(QVariantList rowIndices)
{
    int total = rowIndices.size();
    for (int i = 0; i < total; ++i) {
        int row = rowIndices[i].toInt();
        QString name = tweakNameAt(row);
        emit batchProgress(i, total, name, QStringLiteral("applying"));
        QCoreApplication::processEvents();
        toggleTweak(row);
        emit batchProgress(i + 1, total, name, QStringLiteral("done"));
        QCoreApplication::processEvents();
    }
    emit batchComplete();
}

QString AppController::tweakNameAt(int row) const
{
    if (row < 0 || row >= m_model.rowCount()) return QString();
    return m_model.data(m_model.index(row, 0), TweakListModel::NameRole).toString();
}

QString AppController::tweakCategoryAt(int row) const
{
    if (row < 0 || row >= m_model.rowCount()) return QString();
    return m_model.data(m_model.index(row, 0), TweakListModel::CategoryRole).toString();
}
