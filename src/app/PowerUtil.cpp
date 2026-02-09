#include "app/PowerUtil.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QTextStream>

// ---------------------------------------------------------------------------
// Active power scheme
// ---------------------------------------------------------------------------
QString PowerUtil::activeSchemeGuid()
{
#ifdef Q_OS_WIN
    QProcess proc;
    proc.start(QStringLiteral("powercfg"), {QStringLiteral("/getactivescheme")});
    if (!proc.waitForFinished(3000)) return {};

    const QString output = QString::fromLocal8Bit(proc.readAllStandardOutput());
    static const QRegularExpression re(QStringLiteral("([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})"));
    const auto match = re.match(output);
    return match.hasMatch() ? match.captured(1) : QString();
#else
    return {};
#endif
}

bool PowerUtil::setActiveScheme(const QString &guid)
{
#ifdef Q_OS_WIN
    if (guid.isEmpty()) return false;
    QProcess proc;
    proc.start(QStringLiteral("powercfg"), {QStringLiteral("/setactive"), guid});
    if (!proc.waitForFinished(3000)) return false;
    return proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0;
#else
    Q_UNUSED(guid);
    return false;
#endif
}

bool PowerUtil::ensureUltimatePerformancePlan()
{
#ifdef Q_OS_WIN
    // "powercfg /duplicatescheme e9a42b02-..." creates Ultimate Performance
    QProcess proc;
    proc.start(QStringLiteral("powercfg"),
               {QStringLiteral("/duplicatescheme"),
                QStringLiteral("e9a42b02-d5df-448d-aa00-03f14749eb61")});
    if (!proc.waitForFinished(5000)) return false;
    return proc.exitCode() == 0;
#else
    return false;
#endif
}

// ---------------------------------------------------------------------------
// CS2 path detection
// ---------------------------------------------------------------------------
QStringList PowerUtil::steamLibraryFolders()
{
    QStringList dirs;
#ifdef Q_OS_WIN
    // Default Steam install locations
    const QStringList roots = {
        QStringLiteral("C:/Program Files (x86)/Steam"),
        QStringLiteral("C:/Program Files/Steam"),
        QStringLiteral("D:/SteamLibrary"),
        QStringLiteral("E:/SteamLibrary"),
        QStringLiteral("F:/SteamLibrary")
    };

    for (const QString &root : roots) {
        if (QDir(root).exists())
            dirs.append(root);
    }

    // Parse libraryfolders.vdf for additional library paths
    for (const QString &root : roots) {
        const QString vdfPath = root + QStringLiteral("/steamapps/libraryfolders.vdf");
        QFile vdf(vdfPath);
        if (!vdf.open(QIODevice::ReadOnly | QIODevice::Text)) continue;

        static const QRegularExpression pathRe(QStringLiteral("\"path\"\\s+\"([^\"]+)\""));
        QTextStream stream(&vdf);
        while (!stream.atEnd()) {
            const QString line = stream.readLine();
            const auto m = pathRe.match(line);
            if (m.hasMatch()) {
                QString p = m.captured(1).replace(QStringLiteral("\\\\"), QStringLiteral("/"));
                if (QDir(p).exists() && !dirs.contains(p))
                    dirs.append(p);
            }
        }
        vdf.close();
    }
#endif
    return dirs;
}

QString PowerUtil::detectCs2Path()
{
#ifdef Q_OS_WIN
    const QStringList libs = steamLibraryFolders();
    for (const QString &lib : libs) {
        const QString candidate = lib + QStringLiteral("/steamapps/common/Counter-Strike Global Offensive/game/bin/win64/cs2.exe");
        if (QFileInfo::exists(candidate))
            return QDir::toNativeSeparators(candidate);
    }
#endif
    return {};
}
