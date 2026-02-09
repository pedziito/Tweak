#pragma once

#include <QList>
#include <QVariant>
#include <QString>
#include <QJsonObject>

#include "app/HardwareDetector.h"

struct Tweak
{
    QString id;
    QString category;       // Gaming | Latency | FPS | Network | Power | Services
    QString name;
    QString description;
    bool recommended = false;
    bool applied = false;
    bool requiresAdmin = false;
    QList<QVariantMap> actions;
};

class TweakEngine
{
public:
    TweakEngine();

    QList<Tweak>       &tweaks();
    const QList<Tweak> &tweaks() const;
    QStringList         categories() const;

    void updateRecommendations(const HardwareInfo &info);
    void applyRecommended();
    void restoreDefaults();
    void toggleTweak(const QString &id);
    bool isAdmin() const;

    /// Set a custom CS2 exe path (overrides auto-detect).
    void setCs2Path(const QString &path);
    QString cs2Path() const;

    int appliedCount() const;
    int recommendedCount() const;

private:
    void initializeTweaks();
    void applyTweak(Tweak &tweak);
    void restoreTweak(Tweak &tweak);

    void saveBackup(const QString &id, const QJsonObject &backup);
    QJsonObject loadBackup(const QString &id) const;

    QList<Tweak> m_tweaks;
    QString m_cs2Path;
};
