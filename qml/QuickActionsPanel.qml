import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Rectangle {
    Layout.fillWidth: true
    implicitHeight: qaCol.implicitHeight + 36
    radius: 16
    color: "#111821"
    border.color: "#1c2735"

    ColumnLayout {
        id: qaCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: "Quick Actions"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#d7e2ee"
        }

        Button {
            text: "⚡  Apply Recommended"
            Layout.fillWidth: true
            Material.background: "#1a3a50"
            Material.foreground: "#5ad6ff"
            font.weight: Font.DemiBold
            onClicked: appController.applyRecommended()
        }

        Button {
            text: "↺  Restore Defaults"
            Layout.fillWidth: true
            Material.background: "#1a2230"
            Material.foreground: "#8aa3b8"
            onClicked: appController.restoreDefaults()
        }

        Button {
            text: "🔄  Rescan Hardware"
            Layout.fillWidth: true
            Material.background: "#1a2230"
            Material.foreground: "#8aa3b8"
            onClicked: appController.refreshHardware()
        }

        Button {
            text: "📂  Set CS2 Path"
            Layout.fillWidth: true
            Material.background: "#1a2230"
            Material.foreground: "#8aa3b8"
            onClicked: cs2PathDialog.open()
        }

        Text {
            visible: appController.cs2Path !== ""
            text: "CS2: " + appController.cs2Path
            color: "#5e7a93"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
