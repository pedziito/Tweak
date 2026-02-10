import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Dialogs

Dialog {
    id: dlg
    title: "Set CS2 Executable Path"
    modal: true
    anchors.centerIn: parent
    width: 540
    standardButtons: Dialog.Ok | Dialog.Cancel

    Material.background: "#0f1a2e"
    Material.foreground: "#e2e8f0"
    Material.accent: "#3b82f6"

    background: Rectangle {
        radius: 16
        color: "#0f1a2e"
        border.color: "#1e3a5f"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            text: "Enter or browse to your cs2.exe location.\n" +
                  "Leave empty for auto-detection."
            color: "#94a3b8"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        TextField {
            id: pathField
            Layout.fillWidth: true
            placeholderText: "C:\\...\\cs2.exe"
            text: appController.cs2Path
            color: "#e2e8f0"
            Material.accent: "#3b82f6"
        }

        Text {
            text: "Tip: Default Steam path is\nC:\\Program Files (x86)\\Steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\bin\\win64\\cs2.exe"
            color: "#475569"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    onAccepted: {
        appController.cs2Path = pathField.text.trim()
    }
}
