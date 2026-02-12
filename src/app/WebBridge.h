#pragma once

#include <QObject>
#include <QString>
#include <QJsonArray>
#include <QJsonObject>
#include <QTimer>
#include <QSettings>

#include "app/AppController.h"
#include "app/LicenseManager.h"

/// Bridge between the HTML UI (via QWebChannel) and the C++ AppController.
/// Exposes all data and actions as Q_INVOKABLE methods + signals.
class WebBridge : public QObject
{
    Q_OBJECT

public:
    explicit WebBridge(AppController *controller, LicenseManager *license,
                       QObject *parent = nullptr);

    // ── Data fetchers (called from JS) ──
    Q_INVOKABLE QJsonObject getSystemInfo();
    Q_INVOKABLE QJsonObject getMonitorData();
    Q_INVOKABLE QJsonObject getScoreData();
    Q_INVOKABLE QJsonArray  getTweaks();
    Q_INVOKABLE QJsonArray  getCategories();
    Q_INVOKABLE int         getAppliedCount();
    Q_INVOKABLE int         getRecommendedCount();
    Q_INVOKABLE bool        getIsAdmin();

    // ── License / Auth (async – results come via signals) ──
    Q_INVOKABLE void loginLicense(const QString &username, const QString &password);
    Q_INVOKABLE void activateLicense(const QString &key, const QString &username,
                                     const QString &password);
    Q_INVOKABLE QString getHwid();
    Q_INVOKABLE void checkHwidStatus(const QString &username);

    // ── Actions (called from JS) ──
    Q_INVOKABLE void toggleTweak(int row);
    Q_INVOKABLE void applyAllGaming();
    Q_INVOKABLE void restoreAll();
    Q_INVOKABLE void clearTempFiles();
    Q_INVOKABLE void flushDns();
    Q_INVOKABLE void requestAdmin();
    Q_INVOKABLE void applyRecommended();
    Q_INVOKABLE void verifyAllTweaks();

    // Batch apply with progress
    Q_INVOKABLE void applyBatch(QJsonArray rowIndices);

    // App lifecycle
    Q_INVOKABLE void restartComputer();
    Q_INVOKABLE void closeApp();

    // Credential persistence (QSettings — reliable across restarts)
    Q_INVOKABLE void saveCredentials(const QString &user, const QString &pass, bool save);
    Q_INVOKABLE QJsonObject loadCredentials();
    Q_INVOKABLE void clearCredentials();

signals:
    void tweaksChanged();
    void monitorUpdated();
    void batchProgress(int current, int total, QString name, QString status);
    void batchComplete();
    void loginResult(bool success, const QString &message);
    void activateResult(bool success, const QString &message);
    void hwidStatusResult(const QString &status, const QString &message);
    void showRestartDialog();

private:
    AppController  *m_ctrl;
    LicenseManager *m_license;
    QTimer m_pollTimer;
};
