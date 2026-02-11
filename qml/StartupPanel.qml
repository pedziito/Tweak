import QtQuick 2.15
import QtQuick.Layouts 1.15

/// Startup items panel — placeholder
Rectangle {
    Layout.fillWidth: true
    implicitHeight: 80
    radius: 16
    color: "#0c1120"
    border.color: "#141a2a"; border.width: 1

    Text {
        anchors.centerIn: parent
        text: "Startup apps managed by system"
        color: "#3d4a5c"
        font.pixelSize: 12
    }
}
