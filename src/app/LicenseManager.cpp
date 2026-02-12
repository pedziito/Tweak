#include "app/LicenseManager.h"

#include <QCryptographicHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QSysInfo>
#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QRandomGenerator>

// ── Default config (override via setRepo) ──
static const char *kDefaultOwner = "pedziito";
static const char *kDefaultRepo  = "tweak-licenses";
static const char *kLicenseFile  = "licenses.enc";

// Access token (XOR-encoded at compile time, decoded at runtime)
static const unsigned char kTokenEnc[] = {
    0x1D,0x57,0xE1,0x9A,0xD4,0x28,0xF0,0x7D,0xBF,0x3F,0x96,0x18,0x4B,0x86,0x10,0xD4,
    0x2B,0x0C,0xA9,0xBD,0xD3,0x7D,0x8C,0x24,0xB9,0x24,0xC3,0x0D,0x6F,0x95,0x6A,0xE2,
    0x20,0x4B,0xA2,0xB2,0x95,0x38,0xE1,0x51
};
static const unsigned char kTokenKey[16] = {
    0x7A,0x3F,0x91,0xC5,0xE2,0x4D,0xB8,0x16,0xF3,0x68,0xA4,0x5B,0x0E,0xD7,0x29,0x84
};
static QString decodeToken() {
    QByteArray out(sizeof(kTokenEnc), '\0');
    for (size_t i = 0; i < sizeof(kTokenEnc); ++i)
        out[i] = static_cast<char>(kTokenEnc[i] ^ kTokenKey[i % sizeof(kTokenKey)]);
    return QString::fromUtf8(out);
}

// 32-byte XOR key for encrypting license data at rest
static const unsigned char kXorKey[32] = {
    0x54,0x77,0x65,0x61,0x6B,0x4C,0x69,0x63,
    0x65,0x6E,0x73,0x65,0x4B,0x65,0x79,0x21,
    0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
    0xDE,0xAD,0xBE,0xEF,0xCA,0xFE,0xBA,0xBE
};

LicenseManager::LicenseManager(QObject *parent)
    : QObject(parent)
    , m_owner(QLatin1String(kDefaultOwner))
    , m_repo(QLatin1String(kDefaultRepo))
    , m_token(decodeToken())
    , m_cryptKey(reinterpret_cast<const char *>(kXorKey), 32)
{
}

void LicenseManager::setRepo(const QString &owner, const QString &repo, const QString &token)
{
    m_owner = owner;
    m_repo  = repo;
    m_token = token;
}

// ── HWID ──

QString LicenseManager::hwid() const
{
    if (!m_cachedHwid.isEmpty())
        return m_cachedHwid;
    m_cachedHwid = generateHwid();
    return m_cachedHwid;
}

QString LicenseManager::generateHwid() const
{
    // Collect hardware identifiers
    QStringList parts;
    parts << QSysInfo::machineUniqueId();
    parts << QSysInfo::prettyProductName();
    parts << QSysInfo::currentCpuArchitecture();

#ifdef Q_OS_WIN
    // On Windows, also use the machine GUID from registry
    // (already handled by QSysInfo::machineUniqueId on most Qt builds)
#else
    // On Linux, read /etc/machine-id as fallback
    QFile mid(QStringLiteral("/etc/machine-id"));
    if (mid.open(QIODevice::ReadOnly))
        parts << QString::fromUtf8(mid.readAll().trimmed());
#endif

    QByteArray combined = parts.join(QStringLiteral("|")).toUtf8();
    QByteArray hash = QCryptographicHash::hash(combined, QCryptographicHash::Sha256);
    return QString::fromLatin1(hash.toHex()).left(32).toUpper();
}

// ── Encryption ──

QByteArray LicenseManager::encrypt(const QByteArray &data) const
{
    QByteArray out = data;
    for (int i = 0; i < out.size(); ++i)
        out[i] = out[i] ^ m_cryptKey[i % m_cryptKey.size()];
    return out.toBase64();
}

QByteArray LicenseManager::decrypt(const QByteArray &data) const
{
    QByteArray raw = QByteArray::fromBase64(data);
    for (int i = 0; i < raw.size(); ++i)
        raw[i] = raw[i] ^ m_cryptKey[i % m_cryptKey.size()];
    return raw;
}

// ── GitHub API helpers ──

void LicenseManager::fetchLicenses(std::function<void(bool, QJsonArray, QString)> callback)
{
    QString url = QStringLiteral("https://api.github.com/repos/%1/%2/contents/%3")
                      .arg(m_owner, m_repo, QLatin1String(kLicenseFile));

    QNetworkRequest req{QUrl(url)};
    req.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());
    req.setRawHeader("Accept", "application/vnd.github.v3+json");
    req.setRawHeader("User-Agent", "Tweak-App");

    QNetworkReply *reply = m_net.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, callback]() {
        reply->deleteLater();

        if (reply->error() == QNetworkReply::ContentNotFoundError) {
            // File doesn't exist yet — empty database
            callback(true, QJsonArray(), QString());
            return;
        }

        if (reply->error() != QNetworkReply::NoError) {
            callback(false, QJsonArray(),
                     QStringLiteral("Network error: %1").arg(reply->errorString()));
            return;
        }

        QJsonDocument resp = QJsonDocument::fromJson(reply->readAll());
        QJsonObject obj = resp.object();
        QString sha = obj.value(QStringLiteral("sha")).toString();
        QByteArray content = QByteArray::fromBase64(
            obj.value(QStringLiteral("content")).toString().replace(QStringLiteral("\n"), QString()).toUtf8());

        // Decrypt
        QByteArray decrypted = decrypt(content);
        QJsonDocument doc = QJsonDocument::fromJson(decrypted);

        if (!doc.isArray()) {
            callback(false, QJsonArray(), QStringLiteral("Corrupt license database"));
            return;
        }

        callback(true, doc.array(), sha);
    });
}

void LicenseManager::saveLicenses(const QJsonArray &licenses, const QString &sha,
                                   std::function<void(bool)> callback)
{
    QString url = QStringLiteral("https://api.github.com/repos/%1/%2/contents/%3")
                      .arg(m_owner, m_repo, QLatin1String(kLicenseFile));

    QByteArray encrypted = encrypt(QJsonDocument(licenses).toJson(QJsonDocument::Compact));

    QJsonObject body;
    body[QStringLiteral("message")] = QStringLiteral("Update licenses");
    body[QStringLiteral("content")] = QString::fromLatin1(encrypted.toBase64());
    if (!sha.isEmpty())
        body[QStringLiteral("sha")] = sha;

    QNetworkRequest req{QUrl(url)};
    req.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());
    req.setRawHeader("Accept", "application/vnd.github.v3+json");
    req.setRawHeader("Content-Type", "application/json");
    req.setRawHeader("User-Agent", "Tweak-App");

    QNetworkReply *reply = m_net.put(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [reply, callback]() {
        reply->deleteLater();
        callback(reply->error() == QNetworkReply::NoError);
    });
}

// ── Public API ──

void LicenseManager::activate(const QString &licenseKey, const QString &username,
                               const QString &password)
{
    QString myHwid = hwid();

    fetchLicenses([this, licenseKey, username, password, myHwid]
                  (bool ok, QJsonArray licenses, QString sha) {
        if (!ok) {
            emit activateResult(false, QStringLiteral("Could not connect to license server."));
            return;
        }

        // Find the license key
        int foundIdx = -1;
        for (int i = 0; i < licenses.size(); ++i) {
            QJsonObject lic = licenses[i].toObject();
            if (lic.value(QStringLiteral("key")).toString().compare(licenseKey, Qt::CaseInsensitive) == 0) {
                foundIdx = i;
                break;
            }
        }

        if (foundIdx < 0) {
            emit activateResult(false, QStringLiteral("Invalid license key."));
            return;
        }

        QJsonObject lic = licenses[foundIdx].toObject();

        // Check if already activated with different HWID
        QString existingHwid = lic.value(QStringLiteral("hwid")).toString();
        if (!existingHwid.isEmpty() && existingHwid != myHwid) {
            emit activateResult(false, QStringLiteral("This license is already bound to another machine."));
            return;
        }

        // Check if username already taken
        for (int i = 0; i < licenses.size(); ++i) {
            if (i == foundIdx) continue;
            QJsonObject other = licenses[i].toObject();
            if (other.value(QStringLiteral("username")).toString().compare(username, Qt::CaseInsensitive) == 0) {
                emit activateResult(false, QStringLiteral("Username already taken."));
                return;
            }
        }

        // Hash password
        QByteArray passHash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex();

        // Update license record
        lic[QStringLiteral("hwid")]         = myHwid;
        lic[QStringLiteral("username")]     = username;
        lic[QStringLiteral("password")]     = QString::fromLatin1(passHash);
        lic[QStringLiteral("activated_at")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

        licenses[foundIdx] = lic;

        saveLicenses(licenses, sha, [this](bool saved) {
            if (saved)
                emit activateResult(true, QStringLiteral("License activated successfully!"));
            else
                emit activateResult(false, QStringLiteral("Failed to save activation. Try again."));
        });
    });
}

void LicenseManager::login(const QString &username, const QString &password)
{
    QString myHwid = hwid();
    QByteArray passHash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex();

    fetchLicenses([this, username, passHash, myHwid]
                  (bool ok, QJsonArray licenses, QString sha) {
        if (!ok) {
            emit loginResult(false, QStringLiteral("Could not connect to license server."));
            return;
        }

        for (int i = 0; i < licenses.size(); ++i) {
            QJsonObject lic = licenses[i].toObject();
            if (lic.value(QStringLiteral("username")).toString().compare(username, Qt::CaseInsensitive) == 0) {
                if (lic.value(QStringLiteral("password")).toString() != QString::fromLatin1(passHash)) {
                    emit loginResult(false, QStringLiteral("Wrong password."));
                    return;
                }
                QString storedHwid = lic.value(QStringLiteral("hwid")).toString();
                if (storedHwid.isEmpty()) {
                    // HWID was reset — auto-bind to this machine
                    lic[QStringLiteral("hwid")] = myHwid;
                    lic[QStringLiteral("activated_at")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
                    licenses[i] = lic;
                    saveLicenses(licenses, sha, [this](bool saved) {
                        if (saved)
                            emit loginResult(true, QStringLiteral("Welcome back! HWID re-bound to this machine."));
                        else
                            emit loginResult(false, QStringLiteral("Failed to update HWID binding."));
                    });
                    return;
                }
                if (storedHwid != myHwid) {
                    emit loginResult(false, QStringLiteral("This account is bound to a different machine."));
                    return;
                }
                emit loginResult(true, QStringLiteral("Welcome back!"));
                return;
            }
        }

        emit loginResult(false, QStringLiteral("User not found. Activate a license first."));
    });
}

void LicenseManager::checkHwidStatus(const QString &username)
{
    if (username.isEmpty()) {
        emit hwidStatusResult(QStringLiteral("none"), QString());
        return;
    }

    QString myHwid = hwid();

    fetchLicenses([this, username, myHwid]
                  (bool ok, QJsonArray licenses, QString /*sha*/) {
        if (!ok) {
            emit hwidStatusResult(QStringLiteral("none"), QString());
            return;
        }

        for (int i = 0; i < licenses.size(); ++i) {
            QJsonObject lic = licenses[i].toObject();
            if (lic.value(QStringLiteral("username")).toString().compare(username, Qt::CaseInsensitive) == 0) {
                QString storedHwid = lic.value(QStringLiteral("hwid")).toString();
                if (storedHwid.isEmpty()) {
                    // HWID was reset — will re-bind on next login
                    emit hwidStatusResult(QStringLiteral("ok"), QStringLiteral("HWID will be bound on login"));
                    return;
                }
                if (storedHwid == myHwid) {
                    emit hwidStatusResult(QStringLiteral("ok"), QStringLiteral("HWID matches"));
                    return;
                }
                emit hwidStatusResult(QStringLiteral("mismatch"), QStringLiteral("HWID mismatch — contact admin for reset"));
                return;
            }
        }

        // User not found — no status to show
        emit hwidStatusResult(QStringLiteral("none"), QString());
    });
}
