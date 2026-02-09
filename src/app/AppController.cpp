#include "app/AppController.h"
#include "app/UacHelper.h"

#include <QCoreApplication>

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_detector()
    , m_hwInfo(m_detector.detect())
    , m_engine()
    , m_model(m_engine.tweaks(), this)
    , m_startupScanner()
    , m_settings(this)
{
    // Restore persisted CS2 path
    const QString savedCs2 = m_settings.cs2Path();
    if (!savedCs2.isEmpty())
        m_engine.setCs2Path(savedCs2);

    m_engine.updateRecommendations(m_hwInfo);
    m_model.refresh();
    refreshStartupSuggestions();
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

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
bool AppController::isAdmin()          const { return m_engine.isAdmin(); }
int  AppController::appliedCount()     const { return m_engine.appliedCount(); }
int  AppController::recommendedCount() const { return m_engine.recommendedCount(); }

TweakListModel *AppController::tweaksModel()       { return &m_model; }
QVariantList    AppController::startupSuggestions() const { return m_startupSuggestions; }
QStringList     AppController::categories()         const { return m_engine.categories(); }

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

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------
void AppController::refreshHardware()
{
    m_hwInfo = m_detector.detect();
    m_engine.updateRecommendations(m_hwInfo);
    m_model.refresh();
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
