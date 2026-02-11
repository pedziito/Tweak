import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: card
    height: 56
    radius: 8
    color: "#0c1120"
    border.color: hoverArea.containsMouse ? "#06b6d4" : "#141a2a"
    border.width: 1
    clip: true

    property string gameName: "Game"
    property string gameDesc: "Optimize"
    property color gradStart: "#06b6d4"
    property color gradEnd: "#0ea5e9"
    property bool optimized: false
    property string imagePath: ""

    signal optimize()

    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Left accent stripe
    Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 3; color: card.gradStart
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 8
        spacing: 8

        // Game image or letter circle
        Rectangle {
            width: 32; height: 32; radius: 6
            color: Qt.rgba(card.gradStart.r, card.gradStart.g, card.gradStart.b, 0.15)
            border.color: Qt.rgba(card.gradStart.r, card.gradStart.g, card.gradStart.b, 0.3)
            border.width: 1
            clip: true

            Image {
                anchors.fill: parent
                source: card.imagePath
                visible: card.imagePath !== ""
                fillMode: Image.PreserveAspectCrop
            }

            Text {
                anchors.centerIn: parent
                visible: card.imagePath === ""
                text: card.gameName.charAt(0)
                font.pixelSize: 13; font.weight: Font.Bold
                color: card.gradStart
            }
        }

        // Name + desc
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1

            Text {
                text: card.gameName; color: "#c5d0de"
                font.pixelSize: 12; font.weight: Font.Bold
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text: card.gameDesc; color: "#3d4a5c"; font.pixelSize: 9
                elide: Text.ElideRight; Layout.fillWidth: true
            }
        }

        // Toggle
        Rectangle {
            width: 36; height: 24; radius: 5
            color: card.optimized ? "#0d2818" : "transparent"
            border.color: card.optimized ? "#166534" : Qt.rgba(card.gradStart.r, card.gradStart.g, card.gradStart.b, 0.4)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: card.optimized ? "On" : "Go"
                color: card.optimized ? "#22c55e" : card.gradStart
                font.pixelSize: 9; font.weight: Font.Bold
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: card.optimize()
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }
}