#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QWebChannel>
#include <QUrl>
#include <QStandardPaths>
#include <QPainter>
#include <QIcon>
#include <QPainterPath>

#include "app/AppController.h"
#include "app/WebBridge.h"
#include "app/LicenseManager.h"

static QIcon createAvIcon()
{
    auto makePx = [](int sz) {
        QPixmap px(sz, sz);
        px.fill(Qt::transparent);
        QPainter p(&px);
        p.setRenderHint(QPainter::Antialiasing, true);

        float scaleX = float(sz) / 175.0f;
        float scaleY = float(sz) / 160.0f;
        float s = qMin(scaleX, scaleY);
        float ox = (sz - 175.0f * s) / 2.0f;
        float oy = (sz - 160.0f * s) / 2.0f;
        p.translate(ox, oy);
        p.scale(s, s);

        QLinearGradient grad(0, 0, 175, 0);
        grad.setColorAt(0.0,  QColor(0x1a, 0x3a, 0x6e));
        grad.setColorAt(0.35, QColor(0x19, 0x76, 0xd2));
        grad.setColorAt(0.65, QColor(0x08, 0x91, 0xb2));
        grad.setColorAt(1.0,  QColor(0x22, 0xd3, 0xee));

        p.setPen(Qt::NoPen);
        p.setBrush(grad);

        QPainterPath aPath;
        aPath.setFillRule(Qt::OddEvenFill);
        aPath.moveTo(5,155); aPath.lineTo(55,5); aPath.lineTo(105,155); aPath.closeSubpath();
        aPath.moveTo(55,52); aPath.lineTo(27,155); aPath.lineTo(83,155); aPath.closeSubpath();
        aPath.moveTo(41,105); aPath.lineTo(69,105); aPath.lineTo(72,115); aPath.lineTo(38,115); aPath.closeSubpath();
        p.drawPath(aPath);

        QPainterPath vPath;
        vPath.moveTo(65,5); vPath.lineTo(117,155); vPath.lineTo(169,5);
        vPath.lineTo(152,5); vPath.lineTo(117,130); vPath.lineTo(82,5);
        vPath.closeSubpath();
        p.drawPath(vPath);

        p.end();
        return px;
    };

    QIcon icon;
    for (int sz : {16, 24, 32, 48, 64, 128, 256})
        icon.addPixmap(makePx(sz));
    return icon;
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("ADAMV"));
    QApplication::setOrganizationDomain(QStringLiteral("adamv.local"));
    QApplication::setApplicationName(QStringLiteral("ADAMV TWEAKS"));
    QApplication::setApplicationVersion(QStringLiteral("5.0.0"));
    app.setWindowIcon(createAvIcon());

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
    view.setWindowTitle(QStringLiteral("ADAMV TWEAKS"));
    view.resize(1400, 860);
    view.show();

    return app.exec();
}
