#include "app/WebBridge.h"
#include <QJsonDocument>
#include <QCoreApplication>
#include <QThread>
#include <QFile>

WebBridge::WebBridge(AppController *controller, QObject *parent)
    : QObject(parent), m_ctrl(controller)
{
    // Forward tweak changes
    connect(m_ctrl, &AppController::tweaksChanged, this, &WebBridge::tweaksChanged);

    // Poll system monitor and forward
    connect(m_ctrl->systemMonitor(), &SystemMonitor::updated, this, &WebBridge::monitorUpdated);
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

bool WebBridge::login(const QString &username, const QString &password)
{
    QFile file(QStringLiteral(":/data/users.json"));
    if (!file.open(QIODevice::ReadOnly))
        return false;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    if (!doc.isArray())
        return false;

    const QJsonArray users = doc.array();
    for (const auto &val : users) {
        QJsonObject u = val.toObject();
        if (u.value(QStringLiteral("username")).toString() == username &&
            u.value(QStringLiteral("password")).toString() == password) {
            return true;
        }
    }
    return false;
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
