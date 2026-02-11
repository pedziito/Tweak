#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebChannel>
#include <QUrl>

#include "app/AppController.h"
#include "app/WebBridge.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("Tweak"));
    QApplication::setOrganizationDomain(QStringLiteral("tweak.local"));
    QApplication::setApplicationName(QStringLiteral("Tweak"));
    QApplication::setApplicationVersion(QStringLiteral("5.0.0"));

    AppController controller;

    WebBridge bridge(&controller);
    QWebChannel channel;
    channel.registerObject(QStringLiteral("bridge"), &bridge);

    QWebEngineView view;
    view.page()->setWebChannel(&channel);
    view.setUrl(QUrl(QStringLiteral("qrc:/web/index.html")));
    view.setWindowTitle(QStringLiteral("Tweak"));
    view.resize(1400, 860);
    view.show();

    return app.exec();
}
