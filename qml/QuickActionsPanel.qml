import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    Layout.fillWidth: true
    implicitHeight: qaCol.implicitHeight + 36
    radius: 16
    color: "#0d1117"
    border.color: "#1e293b"

    ColumnLayout {
        id: qaCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: "Quick Actions"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#e2e8f0"
        }

        QAButton { text: "⚡  Apply Recommended"; accent: "#6366f1"; onClicked: appController.applyRecommended() }
        QAButton { text: "↺  Restore Defaults"; accent: "#ef4444"; onClicked: appController.restoreDefaults() }
        QAButton { text: "🔄  Rescan Hardware"; onClicked: appController.refreshHardware() }
        QAButton { text: "📂  Set CS2 Path"; onClicked: cs2PathDialog.open() }

        Text {
            visible: appController.cs2Path !== ""
            text: "CS2: " + appController.cs2Path
            color: "#64748b"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    component QAButton: Rectangle {
        property string text: ""
        property color accent: "#6366f1"
        signal clicked()
        Layout.fillWidth: true
        height: 36
        radius: 10
        color: qaHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.12) : "#111827"
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.3)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: "#a5b4fc"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: qaHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
