#pragma once

#include <QString>
#include <QStringList>

class PowerUtil
{
public:
    /// Return GUID of the currently active power scheme.
    static QString activeSchemeGuid();

    /// Set the active power scheme by GUID. Returns true on success.
    static bool setActiveScheme(const QString &guid);

    /// Create (import) the Ultimate Performance plan if it doesn't exist yet.
    static bool ensureUltimatePerformancePlan();

    /// Auto-detect cs2.exe on common Steam library paths.
    static QString detectCs2Path();

    /// Scan all Steam library folders for cs2.exe.
    static QStringList steamLibraryFolders();
};
