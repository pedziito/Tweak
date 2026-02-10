#include "app/ConfigManager.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDateTime>

ConfigManager::ConfigManager(QObject *parent) : QObject(parent)
{
    // Ensure config directory exists
    QDir().mkpath(configDir());
}

QString ConfigManager::configDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/configs");
}

QVariantList ConfigManager::savedConfigs() const
{
    QVariantList list;
    QDir dir(configDir());
    const auto files = dir.entryInfoList(QStringList() << "*.json", QDir::Files, QDir::Time);

    for (const auto &fi : files) {
        QFile f(fi.absoluteFilePath());
        if (!f.open(QIODevice::ReadOnly)) continue;

        QJsonObject obj = QJsonDocument::fromJson(f.readAll()).object();
        QVariantMap entry;
        entry["name"]      = obj.value("name").toString(fi.baseName());
        entry["created"]   = obj.value("created").toString();
        entry["tweakCount"]= obj.value("tweaks").toArray().size();
        entry["filename"]  = fi.fileName();
        list.append(entry);
    }
    return list;
}

void ConfigManager::saveConfig(const QString &name, const QStringList &appliedTweakIds)
{
    QJsonObject obj;
    obj["name"]    = name;
    obj["created"] = QDateTime::currentDateTime().toString(Qt::ISODate);

    QJsonArray arr;
    for (const auto &id : appliedTweakIds)
        arr.append(id);
    obj["tweaks"] = arr;

    // Sanitize filename
    QString filename = name;
    filename.replace(QRegularExpression("[^a-zA-Z0-9_-]"), "_");
    filename = filename.left(64);

    QFile f(configDir() + "/" + filename + ".json");
    if (f.open(QIODevice::WriteOnly)) {
        f.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
    }
    emit configsChanged();
}

QStringList ConfigManager::loadConfig(const QString &name) const
{
    QString filename = name;
    filename.replace(QRegularExpression("[^a-zA-Z0-9_-]"), "_");
    filename = filename.left(64);

    QFile f(configDir() + "/" + filename + ".json");
    if (!f.open(QIODevice::ReadOnly)) return {};

    QJsonObject obj = QJsonDocument::fromJson(f.readAll()).object();
    QStringList ids;
    const auto arr = obj.value("tweaks").toArray();
    for (const auto &v : arr)
        ids.append(v.toString());
    return ids;
}

void ConfigManager::deleteConfig(const QString &name)
{
    QString filename = name;
    filename.replace(QRegularExpression("[^a-zA-Z0-9_-]"), "_");
    filename = filename.left(64);

    QFile::remove(configDir() + "/" + filename + ".json");
    emit configsChanged();
}

bool ConfigManager::needsRestart() const { return m_needsRestart; }

void ConfigManager::markNeedsRestart()
{
    if (!m_needsRestart) {
        m_needsRestart = true;
        emit needsRestartChanged();
        emit restartRequired();
    }
}

void ConfigManager::clearRestartFlag()
{
    if (m_needsRestart) {
        m_needsRestart = false;
        emit needsRestartChanged();
    }
}
