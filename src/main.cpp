#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QWebChannel>
#include <QUrl>
#include <QStandardPaths>

#include "app/AppController.h"
#include "app/WebBridge.h"
#include "app/LicenseManager.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("Tweak"));
    QApplication::setOrganizationDomain(QStringLiteral("tweak.local"));
    QApplication::setApplicationName(QStringLiteral("Tweak"));
    QApplication::setApplicationVersion(QStringLiteral("5.0.0"));

    AppController controller;
    LicenseManager license;

    WebBridge bridge(&controller, &license);
    QWebChannel channel;
    channel.registerObject(QStringLiteral("bridge"), &bridge);

    QWebEngineView view;

    // Enable persistent local storage for the web engine
    QWebEngineProfile *profile = view.page()->profile();
    profile->setPersistentStoragePath(
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/webdata"));
    view.page()->settings()->setAttribute(QWebEngineSettings::LocalStorageEnabled, true);

    view.page()->setWebChannel(&channel);
    view.setUrl(QUrl(QStringLiteral("qrc:/web/index.html")));
    view.setWindowTitle(QStringLiteral("Tweak"));
    view.resize(1400, 860);
    view.show();

    return app.exec();
}
