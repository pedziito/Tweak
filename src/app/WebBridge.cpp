#include "app/WebBridge.h"
#include <QJsonDocument>
#include <QCoreApplication>
#include <QThread>
#include <QFile>
#include <QProcess>

WebBridge::WebBridge(AppController *controller, LicenseManager *license, QObject *parent)
    : QObject(parent), m_ctrl(controller), m_license(license)
{
    // Forward tweak changes
    connect(m_ctrl, &AppController::tweaksChanged, this, &WebBridge::tweaksChanged);

    // Poll system monitor and forward
    connect(m_ctrl->systemMonitor(), &SystemMonitor::updated, this, &WebBridge::monitorUpdated);

    // Forward license signals
    connect(m_license, &LicenseManager::loginResult,    this, &WebBridge::loginResult);
    connect(m_license, &LicenseManager::activateResult, this, &WebBridge::activateResult);
    connect(m_license, &LicenseManager::hwidStatusResult, this, &WebBridge::hwidStatusResult);
}

QJsonObject WebBridge::getSystemInfo()
{
    QJsonObject obj;
    obj["cpuName"]         = m_ctrl->cpuName();
    obj["gpuName"]         = m_ctrl->gpuName();
    obj["gpuVendor"]       = m_ctrl->gpuVendor();
    obj["totalRam"]        = m_ctrl->totalRam();
    obj["ramText"]         = m_ctrl->ramText();
    obj["cpuCores"]        = m_ctrl->cpuCores();
    obj["cpuThreads"]      = m_ctrl->cpuThreads();
    obj["motherboardName"] = m_ctrl->motherboardName();
    obj["storageText"]     = m_ctrl->storageText();
    obj["diskModel"]       = m_ctrl->diskModel();
    obj["osVersion"]       = m_ctrl->osVersion();
    obj["hasSsd"]          = m_ctrl->hasSsd();
    obj["hasNvme"]         = m_ctrl->hasNvme();
    obj["isAdmin"]         = m_ctrl->isAdmin();
    // Lag 2: Low-Level
    obj["ramType"]         = m_ctrl->ramType();
    obj["ramSpeedMhz"]     = m_ctrl->ramSpeedMhz();
    obj["gpuVramMb"]       = m_ctrl->gpuVramMb();
    obj["gpuDriverVersion"]= m_ctrl->gpuDriverVersion();
    obj["cpuL2CacheKb"]    = m_ctrl->cpuL2CacheKb();
    obj["cpuL3CacheKb"]    = m_ctrl->cpuL3CacheKb();
    // Lag 3: Firmware
    obj["biosVersion"]     = m_ctrl->biosVersion();
    obj["biosDate"]        = m_ctrl->biosDate();
    obj["tpmVersion"]      = m_ctrl->tpmVersion();
    obj["secureBootEnabled"]= m_ctrl->secureBootEnabled();
    obj["chassisType"]     = m_ctrl->chassisType();
    return obj;
}

QJsonObject WebBridge::getMonitorData()
{
    auto *mon = m_ctrl->systemMonitor();
    QJsonObject obj;
    obj["cpuUsage"]       = mon->cpuUsage();
    obj["ramUsage"]       = mon->ramUsage();
    obj["ramUsedGb"]      = mon->ramUsedGb();
    obj["ramTotalGb"]     = mon->ramTotalGb();
    obj["storageUsage"]   = mon->storageUsage();
    obj["storageUsedGb"]  = mon->storageUsedGb();
    obj["storageTotalGb"] = mon->storageTotalGb();
    obj["uptimeText"]     = mon->uptimeText();
    return obj;
}

QJsonObject WebBridge::getScoreData()
{
    auto *sc = m_ctrl->hwScorer();
    QJsonObject obj;
    obj["gamingScore"]      = sc->gamingScore();
    obj["performanceScore"] = sc->performanceScore();
    obj["cpuScore"]         = sc->cpuScore();
    obj["gpuScore"]         = sc->gpuScore();
    obj["ramScore"]         = sc->ramScore();
    obj["storageScore"]     = sc->storageScore();
    obj["tier"]             = sc->tier();
    obj["bottleneck"]       = sc->bottleneck();
    return obj;
}

QJsonArray WebBridge::getTweaks()
{
    QJsonArray arr;
    auto *model = m_ctrl->tweaksModel();
    for (int i = 0; i < model->rowCount(); ++i) {
        QModelIndex idx = model->index(i, 0);
        QJsonObject t;
        t["row"]          = i;
        t["id"]           = model->data(idx, TweakListModel::IdRole).toString();
        t["name"]         = model->data(idx, TweakListModel::NameRole).toString();
        t["description"]  = model->data(idx, TweakListModel::DescriptionRole).toString();
        t["category"]     = model->data(idx, TweakListModel::CategoryRole).toString();
        t["recommended"]  = model->data(idx, TweakListModel::RecommendedRole).toBool();
        t["applied"]      = model->data(idx, TweakListModel::AppliedRole).toBool();
        t["requiresAdmin"]= model->data(idx, TweakListModel::RequiresAdminRole).toBool();
        t["risk"]         = model->data(idx, TweakListModel::RiskRole).toString();
        t["learnMore"]    = model->data(idx, TweakListModel::LearnMoreRole).toString();
        t["verified"]     = model->data(idx, TweakListModel::VerifiedRole).toBool();
        t["status"]       = model->data(idx, TweakListModel::StatusRole).toString();
        arr.append(t);
    }
    return arr;
}

QJsonArray WebBridge::getCategories()
{
    QJsonArray arr;
    for (const auto &c : m_ctrl->categories())
        arr.append(c);
    return arr;
}

void WebBridge::loginLicense(const QString &username, const QString &password)
{
    m_license->login(username, password);
}

void WebBridge::activateLicense(const QString &key, const QString &username,
                                const QString &password)
{
    m_license->activate(key, username, password);
}

QString WebBridge::getHwid()
{
    return m_license->hwid();
}

void WebBridge::checkHwidStatus(const QString &username)
{
    m_license->checkHwidStatus(username);
}

int  WebBridge::getAppliedCount()     { return m_ctrl->appliedCount(); }
int  WebBridge::getRecommendedCount() { return m_ctrl->recommendedCount(); }
bool WebBridge::getIsAdmin()          { return m_ctrl->isAdmin(); }

void WebBridge::toggleTweak(int row)     { m_ctrl->toggleTweak(row); }
void WebBridge::applyAllGaming()         { m_ctrl->applyAllGaming(); }
void WebBridge::restoreAll()             { m_ctrl->restoreAll(); }
void WebBridge::clearTempFiles()         { m_ctrl->clearTempFiles(); }
void WebBridge::flushDns()               { m_ctrl->flushDns(); }
void WebBridge::requestAdmin()           { m_ctrl->requestAdmin(); }
void WebBridge::applyRecommended()       { m_ctrl->applyRecommended(); }
void WebBridge::verifyAllTweaks()        { m_ctrl->verifyAllTweaks(); }

void WebBridge::applyBatch(QJsonArray rowIndices)
{
    int total = rowIndices.size();
    for (int i = 0; i < total; ++i) {
        int row = rowIndices[i].toInt();
        QString name;
        auto *model = m_ctrl->tweaksModel();
        if (row >= 0 && row < model->rowCount()) {
            name = model->data(model->index(row, 0), TweakListModel::NameRole).toString();
        }
        emit batchProgress(i, total, name, "applying");
        QCoreApplication::processEvents();        // deliver signal to JS
        QThread::msleep(80);                       // small delay for visual feedback
        m_ctrl->toggleTweak(row);
        emit batchProgress(i + 1, total, name, "done");
        QCoreApplication::processEvents();         // deliver done signal
    }
    emit batchComplete();
}

// ── Credential persistence via QSettings ──

void WebBridge::saveCredentials(const QString &user, const QString &pass, bool save)
{
    QSettings s;
    s.beginGroup(QStringLiteral("Credentials"));
    if (save && !user.isEmpty()) {
        s.setValue(QStringLiteral("username"), user);
        s.setValue(QStringLiteral("password"), pass);
        s.setValue(QStringLiteral("remember"), true);
    } else {
        s.remove(QStringLiteral(""));
    }
    s.endGroup();
    s.sync();
}

QJsonObject WebBridge::loadCredentials()
{
    QSettings s;
    s.beginGroup(QStringLiteral("Credentials"));
    QJsonObject obj;
    obj[QStringLiteral("remember")] = s.value(QStringLiteral("remember"), false).toBool();
    obj[QStringLiteral("username")] = s.value(QStringLiteral("username"), QString()).toString();
    obj[QStringLiteral("password")] = s.value(QStringLiteral("password"), QString()).toString();
    s.endGroup();
    return obj;
}

void WebBridge::clearCredentials()
{
    QSettings s;
    s.beginGroup(QStringLiteral("Credentials"));
    s.remove(QStringLiteral(""));
    s.endGroup();
    s.sync();
}

void WebBridge::restartComputer()
{
#ifdef Q_OS_WIN
    QProcess::startDetached(QStringLiteral("shutdown"), {"/r", "/t", "3", "/c", "ADAMV TWEAKS: Restarting to apply changes"});
#else
    QProcess::startDetached(QStringLiteral("systemctl"), {"reboot"});
#endif
    QCoreApplication::quit();
}

void WebBridge::closeApp()
{
    QCoreApplication::quit();
}
