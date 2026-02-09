#include "app/StartupScanner.h"

#include <QDir>
#include <QFileInfoList>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#include <QSettings>
#endif

namespace {

#ifdef Q_OS_WIN
void appendRunKey(QVariantList &items, const QString &regRoot, const QString &label)
{
    QSettings settings(regRoot, QSettings::NativeFormat);
    const QStringList keys = settings.allKeys();
    for (const QString &key : keys) {
        QVariantMap item;
        item[QStringLiteral("name")]    = key;
        item[QStringLiteral("command")] = settings.value(key).toString();
        item[QStringLiteral("source")]  = label;
        items.append(item);
    }
}
#endif

void appendStartupFolder(QVariantList &items, const QString &folder, const QString &label)
{
    QDir dir(folder);
    if (!dir.exists()) return;
    const QFileInfoList files = dir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
    for (const QFileInfo &fi : files) {
        QVariantMap item;
        item[QStringLiteral("name")]    = fi.completeBaseName();
        item[QStringLiteral("command")] = fi.absoluteFilePath();
        item[QStringLiteral("source")]  = label;
        items.append(item);
    }
}

} // anonymous namespace

QVariantList StartupScanner::scan() const
{
    QVariantList items;

#ifdef Q_OS_WIN
    appendRunKey(items,
                 QStringLiteral("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
                 QStringLiteral("HKCU Run"));
    appendRunKey(items,
                 QStringLiteral("HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
                 QStringLiteral("HKLM Run"));

    const QString startupUser = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)
                                + QStringLiteral("/Startup");
    appendStartupFolder(items, startupUser, QStringLiteral("Startup Folder"));

    const QString startupCommon = QStringLiteral("C:/ProgramData/Microsoft/Windows/Start Menu/Programs/Startup");
    appendStartupFolder(items, startupCommon, QStringLiteral("All Users Startup"));
#endif

    return items;
}
