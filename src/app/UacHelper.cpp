#include "app/UacHelper.h"

#include <QCoreApplication>

#ifdef Q_OS_WIN
#include <Windows.h>
#include <shellapi.h>
#endif

UacHelper::UacHelper(QObject *parent)
    : QObject(parent)
{
}

bool UacHelper::isRunningAsAdmin()
{
#ifdef Q_OS_WIN
    BOOL isAdmin = FALSE;
    SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
    PSID adminGroup = nullptr;
    if (AllocateAndInitializeSid(&ntAuthority, 2,
                                  SECURITY_BUILTIN_DOMAIN_RID,
                                  DOMAIN_ALIAS_RID_ADMINS,
                                  0, 0, 0, 0, 0, 0,
                                  &adminGroup))
    {
        CheckTokenMembership(nullptr, adminGroup, &isAdmin);
        FreeSid(adminGroup);
    }
    return isAdmin != FALSE;
#else
    return false;
#endif
}

bool UacHelper::relaunchAsAdmin()
{
#ifdef Q_OS_WIN
    const QString exe = QCoreApplication::applicationFilePath().replace(QLatin1Char('/'), QLatin1Char('\\'));

    SHELLEXECUTEINFOW sei = {};
    sei.cbSize = sizeof(sei);
    sei.lpVerb = L"runas";
    sei.lpFile = reinterpret_cast<LPCWSTR>(exe.utf16());
    sei.nShow  = SW_SHOWNORMAL;
    sei.fMask  = SEE_MASK_NOASYNC;

    if (ShellExecuteExW(&sei)) {
        // Elevated process was launched – caller should QCoreApplication::quit().
        return true;
    }
    // User cancelled UAC or an error occurred.
    return false;
#else
    return false;
#endif
}
