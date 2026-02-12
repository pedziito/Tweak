#pragma once

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkAccessManager>

/// Manages license keys, HWID binding, and authentication via a private GitHub repo.
/// License data is stored encrypted in a private GitHub repository.
class LicenseManager : public QObject
{
    Q_OBJECT

public:
    explicit LicenseManager(QObject *parent = nullptr);

    /// Get the hardware ID for this machine (SHA-256 hash of hardware info).
    QString hwid() const;

    /// Activate a license key: binds HWID, sets username/password.
    /// Calls GitHub API to validate key and update the license record.
    /// Returns result asynchronously via activateResult signal.
    void activate(const QString &licenseKey, const QString &username, const QString &password);

    /// Login: checks credentials + HWID against the remote license database.
    /// Returns result asynchronously via loginResult signal.
    void login(const QString &username, const QString &password);

    /// Set the GitHub repo and token used for license storage.
    /// Defaults are compiled in but can be overridden.
    void setRepo(const QString &owner, const QString &repo, const QString &token);

signals:
    void loginResult(bool success, const QString &message);
    void activateResult(bool success, const QString &message);

private:
    void fetchLicenses(std::function<void(bool ok, QJsonArray licenses, QString sha)> callback);
    void saveLicenses(const QJsonArray &licenses, const QString &sha,
                      std::function<void(bool ok)> callback);

    QByteArray encrypt(const QByteArray &data) const;
    QByteArray decrypt(const QByteArray &data) const;
    QString generateHwid() const;

    QNetworkAccessManager m_net;
    QString m_owner;
    QString m_repo;
    QString m_token;
    QByteArray m_cryptKey;
    mutable QString m_cachedHwid;
};
