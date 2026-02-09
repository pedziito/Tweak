#pragma once

#include <QObject>
#include <QString>

/// Helper for UAC elevation on Windows.
/// Relaunches the current process elevated when admin is needed.
class UacHelper : public QObject
{
    Q_OBJECT

public:
    explicit UacHelper(QObject *parent = nullptr);

    /// Returns true when the process is running with admin privileges.
    static bool isRunningAsAdmin();

    /// Attempt to relaunch the application elevated via ShellExecute "runas".
    /// Returns true if the elevated process was launched (caller should quit).
    Q_INVOKABLE static bool relaunchAsAdmin();
};
