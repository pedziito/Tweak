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

    Material.background: "#0c1120"
    Material.foreground: "#c5d0de"
    Material.accent: "#06b6d4"

    background: Rectangle {
        radius: 16
        color: "#0c1120"
        border.color: "#141a2a"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            text: "Enter or browse to your cs2.exe location.\n" +
                  "Leave empty for auto-detection."
            color: "#7b8ba3"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        TextField {
            id: pathField
            Layout.fillWidth: true
            placeholderText: "C:\\...\\cs2.exe"
            text: appController.cs2Path
            color: "#c5d0de"
            Material.accent: "#06b6d4"
        }

        Text {
            text: "Tip: Default Steam path is\nC:\\Program Files (x86)\\Steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\bin\\win64\\cs2.exe"
            color: "#3d4a5c"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    onAccepted: {
        appController.cs2Path = pathField.text.trim()
    }
}
