import QtQuick 2.15
import QtQuick.Layouts 1.15

/// Quick actions panel — standalone version
Rectangle {
    Layout.fillWidth: true
    implicitHeight: qaCol.implicitHeight + 36
    radius: 16
    color: "#12172b"
    border.color: "#1c2333"; border.width: 1

    ColumnLayout {
        id: qaCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: "Quick Actions"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#c5d0de"
        }

        QAButton { text: "\u26A1  Apply Recommended"; accent: "#06b6d4"; onClicked: appController.applyRecommended() }
        QAButton { text: "\u21BA  Restore Defaults";  accent: "#f43f5e"; onClicked: appController.restoreDefaults() }
        QAButton { text: "\u21BB  Rescan Hardware";    accent: "#f59e0b"; onClicked: appController.refreshHardware() }
        QAButton { text: "\u25CE  Set CS2 Path";       accent: "#8b5cf6"; onClicked: cs2PathDialog.open() }

        Text {
            visible: appController.cs2Path !== ""
            text: "CS2: " + appController.cs2Path
            color: "#3d4a5c"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    component QAButton: Rectangle {
        property string text: ""
        property color accent: "#06b6d4"
        signal clicked()
        Layout.fillWidth: true
        height: 34
        radius: 8
        color: qaHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.1) : "#0f1423"
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.25)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: parent.accent
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: qaHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
