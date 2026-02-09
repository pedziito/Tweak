#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>

#include "app/AppController.h"
#include "app/UacHelper.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("Tweak"));
    QApplication::setOrganizationDomain(QStringLiteral("tweak.local"));
    QApplication::setApplicationName(QStringLiteral("Tweak"));
    QApplication::setApplicationVersion(QStringLiteral("1.0.0"));

    QQuickStyle::setStyle(QStringLiteral("Material"));

    QQmlApplicationEngine engine;

    AppController controller;
    engine.rootContext()->setContextProperty(QStringLiteral("appController"), &controller);

    const QUrl url(QStringLiteral("qrc:/Tweak/qml/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
