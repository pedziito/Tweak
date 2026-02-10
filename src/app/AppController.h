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
#include "app/BenchmarkEngine.h"
#include "app/SystemMonitor.h"
#include "app/HardwareScorer.h"
#include "app/GameBenchmark.h"
#include "app/ConfigManager.h"

class AppController : public QObject
{
    Q_OBJECT

    // Hardware info
    Q_PROPERTY(QString cpuName          READ cpuName          NOTIFY hardwareChanged)
    Q_PROPERTY(QString gpuName          READ gpuName          NOTIFY hardwareChanged)
    Q_PROPERTY(QString gpuVendor        READ gpuVendor        NOTIFY hardwareChanged)
    Q_PROPERTY(QString totalRam         READ totalRam         NOTIFY hardwareChanged)
    Q_PROPERTY(QString ramText          READ ramText          NOTIFY hardwareChanged)
    Q_PROPERTY(int     cpuCores         READ cpuCores         NOTIFY hardwareChanged)
    Q_PROPERTY(int     cpuThreads       READ cpuThreads       NOTIFY hardwareChanged)
    Q_PROPERTY(QString motherboardName  READ motherboardName  NOTIFY hardwareChanged)
    Q_PROPERTY(QString storageText      READ storageText      NOTIFY hardwareChanged)
    Q_PROPERTY(QString diskModel        READ diskModel        NOTIFY hardwareChanged)
    Q_PROPERTY(QString osVersion        READ osVersion        NOTIFY hardwareChanged)
    Q_PROPERTY(bool    hasSsd           READ hasSsd           NOTIFY hardwareChanged)
    Q_PROPERTY(bool    hasNvme          READ hasNvme          NOTIFY hardwareChanged)

    // State
    Q_PROPERTY(bool    isAdmin          READ isAdmin          CONSTANT)
    Q_PROPERTY(int     appliedCount     READ appliedCount     NOTIFY tweaksChanged)
    Q_PROPERTY(int     recommendedCount READ recommendedCount NOTIFY tweaksChanged)

    // Models
    Q_PROPERTY(TweakListModel* tweaksModel READ tweaksModel CONSTANT)
    Q_PROPERTY(TweakListModel* tweakModel  READ tweaksModel CONSTANT)
    Q_PROPERTY(QVariantList startupSuggestions READ startupSuggestions NOTIFY startupChanged)
    Q_PROPERTY(QStringList  categories        READ categories         CONSTANT)

    // Settings
    Q_PROPERTY(QString cs2Path          READ cs2Path   WRITE setCs2Path NOTIFY cs2PathChanged)
    Q_PROPERTY(QString selectedCategory READ selectedCategory WRITE setSelectedCategory NOTIFY selectedCategoryChanged)
    Q_PROPERTY(QString filterText       READ filterText WRITE setFilterText NOTIFY filterTextChanged)

    // Benchmark
    Q_PROPERTY(QVariantList benchmarkResults    READ benchmarkResults    NOTIFY benchmarkChanged)
    Q_PROPERTY(bool         benchmarkRunning    READ benchmarkRunning    NOTIFY benchmarkRunningChanged)
    Q_PROPERTY(bool         benchmarkHasBaseline READ benchmarkHasBaseline NOTIFY benchmarkChanged)

    // System Monitor
    Q_PROPERTY(SystemMonitor* systemMonitor READ systemMonitor CONSTANT)

    // Hardware Scorer
    Q_PROPERTY(HardwareScorer* hwScorer READ hwScorer CONSTANT)

    // Game Benchmark
    Q_PROPERTY(GameBenchmark* gameBenchmark READ gameBenchmark CONSTANT)

    // Config Manager
    Q_PROPERTY(ConfigManager* configManager READ configManager CONSTANT)

public:
    explicit AppController(QObject *parent = nullptr);

    // Hardware getters
    QString cpuName() const;
    QString gpuName() const;
    QString gpuVendor() const;
    QString totalRam() const;
    QString ramText() const;
    int     cpuCores() const;
    int     cpuThreads() const;
    QString motherboardName() const;
    QString storageText() const;
    QString diskModel() const;
    QString osVersion() const;
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
    QString filterText() const;
    void    setFilterText(const QString &text);

    // Benchmark
    QVariantList benchmarkResults() const;
    bool benchmarkRunning() const;
    bool benchmarkHasBaseline() const;

    // System Monitor
    SystemMonitor* systemMonitor();

    // Hardware Scorer
    HardwareScorer* hwScorer();

    // Game Benchmark
    GameBenchmark* gameBenchmark();

    // Config Manager
    ConfigManager* configManager();

    // Actions
    Q_INVOKABLE void refreshHardware();
    Q_INVOKABLE void applyRecommended();
    Q_INVOKABLE void restoreDefaults();
    Q_INVOKABLE void toggleTweak(int row);
    Q_INVOKABLE bool requestAdmin();
    Q_INVOKABLE void runBaseline();
    Q_INVOKABLE void runAfterTweaks();
    Q_INVOKABLE void resetBenchmark();

    // New QML-invokable actions
    Q_INVOKABLE void applyAllGaming();
    Q_INVOKABLE void restoreAll();
    Q_INVOKABLE void clearTempFiles();
    Q_INVOKABLE void flushDns();

    // Game benchmark actions
    Q_INVOKABLE void runGameBenchmark();

    // Config actions
    Q_INVOKABLE void saveConfiguration(const QString &name);
    Q_INVOKABLE QStringList loadConfiguration(const QString &name);
    Q_INVOKABLE void deleteConfiguration(const QString &name);
    Q_INVOKABLE QStringList appliedTweakIds() const;

    // Verification
    Q_INVOKABLE bool verifyTweak(int row);
    Q_INVOKABLE void verifyAllTweaks();

signals:
    void hardwareChanged();
    void tweaksChanged();
    void startupChanged();
    void cs2PathChanged();
    void selectedCategoryChanged();
    void filterTextChanged();
    void benchmarkChanged();
    void benchmarkRunningChanged();

private:
    void refreshStartupSuggestions();

    HardwareDetector m_detector;
    HardwareInfo     m_hwInfo;
    TweakEngine      m_engine;
    TweakListModel   m_model;
    StartupScanner   m_startupScanner;
    SettingsManager  m_settings;
    QVariantList     m_startupSuggestions;
    BenchmarkEngine  m_benchmark;
    SystemMonitor    m_systemMonitor;
    HardwareScorer   m_scorer;
    GameBenchmark    m_gameBenchmark;
    ConfigManager    m_configManager;
    QString          m_filterText;
};
