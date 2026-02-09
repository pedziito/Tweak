#include "app/RegistryUtil.h"

#ifdef Q_OS_WIN
#include <QSettings>
#endif

namespace {

#ifdef Q_OS_WIN
QString registryRoot(const QString &hive, const QString &path)
{
    QString root = hive;
    if (hive.compare(QStringLiteral("HKLM"), Qt::CaseInsensitive) == 0)
        root = QStringLiteral("HKEY_LOCAL_MACHINE");
    else if (hive.compare(QStringLiteral("HKCU"), Qt::CaseInsensitive) == 0)
        root = QStringLiteral("HKEY_CURRENT_USER");
    else if (hive.compare(QStringLiteral("HKCR"), Qt::CaseInsensitive) == 0)
        root = QStringLiteral("HKEY_CLASSES_ROOT");
    return root + QStringLiteral("\\") + path;
}
#endif

} // anonymous namespace

RegistryValue RegistryUtil::readValue(const QString &hive, const QString &path, const QString &name)
{
    RegistryValue result;
#ifdef Q_OS_WIN
    QSettings settings(registryRoot(hive, path), QSettings::NativeFormat);
    if (settings.contains(name)) {
        result.exists = true;
        result.value = settings.value(name);
    }
#else
    Q_UNUSED(hive); Q_UNUSED(path); Q_UNUSED(name);
#endif
    return result;
}

bool RegistryUtil::writeValue(const QString &hive, const QString &path, const QString &name, const QVariant &value)
{
#ifdef Q_OS_WIN
    QSettings settings(registryRoot(hive, path), QSettings::NativeFormat);
    settings.setValue(name, value);
    settings.sync();
    return settings.status() == QSettings::NoError;
#else
    Q_UNUSED(hive); Q_UNUSED(path); Q_UNUSED(name); Q_UNUSED(value);
    return false;
#endif
}

bool RegistryUtil::deleteValue(const QString &hive, const QString &path, const QString &name)
{
#ifdef Q_OS_WIN
    QSettings settings(registryRoot(hive, path), QSettings::NativeFormat);
    settings.remove(name);
    settings.sync();
    return settings.status() == QSettings::NoError;
#else
    Q_UNUSED(hive); Q_UNUSED(path); Q_UNUSED(name);
    return false;
#endif
}
