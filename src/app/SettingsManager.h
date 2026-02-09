#pragma once

#include <QObject>
#include <QString>
#include <QSettings>

/// Persists user preferences (e.g. custom CS2 path).
class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString cs2Path READ cs2Path WRITE setCs2Path NOTIFY cs2PathChanged)
    Q_PROPERTY(QString selectedCategory READ selectedCategory WRITE setSelectedCategory NOTIFY selectedCategoryChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    QString cs2Path() const;
    void setCs2Path(const QString &path);

    QString selectedCategory() const;
    void setSelectedCategory(const QString &cat);

signals:
    void cs2PathChanged();
    void selectedCategoryChanged();

private:
    QSettings m_settings;
};
