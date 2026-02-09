#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

#include "app/HardwareDetector.h"
#include "app/TweakEngine.h"
#include "app/TweakListModel.h"
#include "app/StartupScanner.h"
#include "app/SettingsManager.h"

class AppController : public QObject
{
    Q_OBJECT

    // Hardware info
    Q_PROPERTY(QString cpuName          READ cpuName          NOTIFY hardwareChanged)
    Q_PROPERTY(QString gpuName          READ gpuName          NOTIFY hardwareChanged)
    Q_PROPERTY(QString gpuVendor        READ gpuVendor        NOTIFY hardwareChanged)
    Q_PROPERTY(QString ramText          READ ramText          NOTIFY hardwareChanged)
    Q_PROPERTY(int     cpuCores         READ cpuCores         NOTIFY hardwareChanged)
    Q_PROPERTY(int     cpuThreads       READ cpuThreads       NOTIFY hardwareChanged)
    Q_PROPERTY(QString motherboardName  READ motherboardName  NOTIFY hardwareChanged)
    Q_PROPERTY(QString storageText      READ storageText      NOTIFY hardwareChanged)
    Q_PROPERTY(bool    hasSsd           READ hasSsd           NOTIFY hardwareChanged)
    Q_PROPERTY(bool    hasNvme          READ hasNvme          NOTIFY hardwareChanged)

    // State
    Q_PROPERTY(bool    isAdmin          READ isAdmin          CONSTANT)
    Q_PROPERTY(int     appliedCount     READ appliedCount     NOTIFY tweaksChanged)
    Q_PROPERTY(int     recommendedCount READ recommendedCount NOTIFY tweaksChanged)

    // Models
    Q_PROPERTY(TweakListModel* tweaksModel READ tweaksModel CONSTANT)
    Q_PROPERTY(QVariantList startupSuggestions READ startupSuggestions NOTIFY startupChanged)
    Q_PROPERTY(QStringList  categories        READ categories         CONSTANT)

    // Settings
    Q_PROPERTY(QString cs2Path          READ cs2Path   WRITE setCs2Path NOTIFY cs2PathChanged)
    Q_PROPERTY(QString selectedCategory READ selectedCategory WRITE setSelectedCategory NOTIFY selectedCategoryChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    // Hardware getters
    QString cpuName() const;
    QString gpuName() const;
    QString gpuVendor() const;
    QString ramText() const;
    int     cpuCores() const;
    int     cpuThreads() const;
    QString motherboardName() const;
    QString storageText() const;
    bool    hasSsd() const;
    bool    hasNvme() const;

    // State
    bool isAdmin() const;
    int  appliedCount() const;
    int  recommendedCount() const;

    // Models
    TweakListModel* tweaksModel();
    QVariantList    startupSuggestions() const;
    QStringList     categories() const;

    // Settings
    QString cs2Path() const;
    void    setCs2Path(const QString &path);
    QString selectedCategory() const;
    void    setSelectedCategory(const QString &cat);

    // Actions
    Q_INVOKABLE void refreshHardware();
    Q_INVOKABLE void applyRecommended();
    Q_INVOKABLE void restoreDefaults();
    Q_INVOKABLE void toggleTweak(int row);
    Q_INVOKABLE bool requestAdmin();

signals:
    void hardwareChanged();
    void tweaksChanged();
    void startupChanged();
    void cs2PathChanged();
    void selectedCategoryChanged();

private:
    void refreshStartupSuggestions();

    HardwareDetector m_detector;
    HardwareInfo     m_hwInfo;
    TweakEngine      m_engine;
    TweakListModel   m_model;
    StartupScanner   m_startupScanner;
    SettingsManager  m_settings;
    QVariantList     m_startupSuggestions;
};
