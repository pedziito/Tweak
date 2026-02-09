#include "app/SettingsManager.h"

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("Tweak"), QStringLiteral("Tweak"))
{
}

QString SettingsManager::cs2Path() const
{
    return m_settings.value(QStringLiteral("cs2Path")).toString();
}

void SettingsManager::setCs2Path(const QString &path)
{
    if (cs2Path() == path) return;
    m_settings.setValue(QStringLiteral("cs2Path"), path);
    m_settings.sync();
    emit cs2PathChanged();
}

QString SettingsManager::selectedCategory() const
{
    return m_settings.value(QStringLiteral("selectedCategory"), QStringLiteral("All")).toString();
}

void SettingsManager::setSelectedCategory(const QString &cat)
{
    if (selectedCategory() == cat) return;
    m_settings.setValue(QStringLiteral("selectedCategory"), cat);
    m_settings.sync();
    emit selectedCategoryChanged();
}
