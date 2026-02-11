#pragma once

#include <QObject>
#include <QString>
#include <QJsonArray>
#include <QJsonObject>
#include <QTimer>

#include "app/AppController.h"

/// Bridge between the HTML UI (via QWebChannel) and the C++ AppController.
/// Exposes all data and actions as Q_INVOKABLE methods + signals.
class WebBridge : public QObject
{
    Q_OBJECT

public:
    explicit WebBridge(AppController *controller, QObject *parent = nullptr);

    // ── Data fetchers (called from JS) ──
    Q_INVOKABLE QJsonObject getSystemInfo();
    Q_INVOKABLE QJsonObject getMonitorData();
    Q_INVOKABLE QJsonObject getScoreData();
    Q_INVOKABLE QJsonArray  getTweaks();
    Q_INVOKABLE QJsonArray  getCategories();
    Q_INVOKABLE int         getAppliedCount();
    Q_INVOKABLE int         getRecommendedCount();
    Q_INVOKABLE bool        getIsAdmin();

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

signals:
    void tweaksChanged();
    void monitorUpdated();
    void batchProgress(int current, int total, QString name, QString status);
    void batchComplete();

private:
    AppController *m_ctrl;
    QTimer m_pollTimer;
};
