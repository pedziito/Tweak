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

    Material.background: "#131a23"
    Material.foreground: "#e6edf6"
    Material.accent: "#5ad6ff"

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            text: "Enter or browse to your cs2.exe location.\n" +
                  "Leave empty for auto-detection."
            color: "#8aa3b8"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        TextField {
            id: pathField
            Layout.fillWidth: true
            placeholderText: "C:\\...\\cs2.exe"
            text: appController.cs2Path
            color: "#e6edf6"
            Material.accent: "#5ad6ff"
        }

        Text {
            text: "Tip: Default Steam path is\nC:\\Program Files (x86)\\Steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\bin\\win64\\cs2.exe"
            color: "#4a6578"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    onAccepted: {
        appController.cs2Path = pathField.text.trim()
    }
}
