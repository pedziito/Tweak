#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebChannel>
#include <QFile>
#include <QUrl>

#include "app/AppController.h"
#include "app/WebBridge.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("Tweak"));
    QApplication::setOrganizationDomain(QStringLiteral("tweak.local"));
    QApplication::setApplicationName(QStringLiteral("Tweak"));
    QApplication::setApplicationVersion(QStringLiteral("4.2.0"));

    // ── Backend ──
    AppController controller;

    // ── WebChannel bridge ──
    WebBridge bridge(&controller);
    QWebChannel channel;
    channel.registerObject(QStringLiteral("bridge"), &bridge);

    // ── WebEngine view ──
    QWebEngineView view;
    view.page()->setWebChannel(&channel);
    view.setUrl(QUrl(QStringLiteral("qrc:/web/index.html")));
    view.setWindowTitle(QStringLiteral("Tweak — Gaming Optimizer"));
    view.resize(1280, 800);
    view.show();

    return app.exec();
}
