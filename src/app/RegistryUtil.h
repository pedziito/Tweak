#pragma once

#include <QString>
#include <QVariant>

struct RegistryValue
{
    bool exists = false;
    QVariant value;
};

class RegistryUtil
{
public:
    static RegistryValue readValue(const QString &hive, const QString &path, const QString &name);
    static bool writeValue(const QString &hive, const QString &path, const QString &name, const QVariant &value);
    static bool deleteValue(const QString &hive, const QString &path, const QString &name);
};
