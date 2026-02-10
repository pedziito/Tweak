#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QJsonObject>

/// Manages save/load of tweak configurations and provides
/// restart-required detection.
class ConfigManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList savedConfigs READ savedConfigs NOTIFY configsChanged)
    Q_PROPERTY(bool needsRestart READ needsRestart NOTIFY needsRestartChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr);

    QVariantList savedConfigs() const;
    bool needsRestart() const;

    /// Save current applied tweak IDs to a named profile.
    Q_INVOKABLE void saveConfig(const QString &name, const QStringList &appliedTweakIds);

    /// Load a saved profile — returns list of tweak IDs to apply.
    Q_INVOKABLE QStringList loadConfig(const QString &name) const;

    /// Delete a saved profile.
    Q_INVOKABLE void deleteConfig(const QString &name);

    /// Mark that system changes were made that require restart.
    void markNeedsRestart();

    /// Clear restart flag (after user restarts or dismisses).
    Q_INVOKABLE void clearRestartFlag();

signals:
    void configsChanged();
    void needsRestartChanged();
    void restartRequired(); // emitted once when restart becomes needed

private:
    QString configDir() const;
    bool m_needsRestart = false;
};
