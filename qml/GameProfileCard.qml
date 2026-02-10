import QtQuick 2.15
import QtQuick.Layouts 1.15

/// Compact game profile card — fits in a 2-column grid
Rectangle {
    id: card
    height: 100
    radius: 12
    color: "#12172b"
    border.color: hoverArea.containsMouse ? "#06b6d4" : "#1c2333"
    border.width: 1
    clip: true

    property string gameName: "Game"
    property string gameDesc: "Optimize"
    property color gradStart: "#06b6d4"
    property color gradEnd: "#0ea5e9"
    property bool optimized: false

    signal optimize()

    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Left accent stripe
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4; radius: 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: card.gradStart }
            GradientStop { position: 1.0; color: card.gradEnd }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 12

        // Icon circle
        Rectangle {
            width: 36; height: 36; radius: 18
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(card.gradStart.r, card.gradStart.g, card.gradStart.b, 0.2) }
                GradientStop { position: 1.0; color: Qt.rgba(card.gradEnd.r, card.gradEnd.g, card.gradEnd.b, 0.1) }
            }
            border.color: Qt.rgba(card.gradStart.r, card.gradStart.g, card.gradStart.b, 0.3)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: card.gameName.charAt(0)
                font.pixelSize: 14
                font.weight: Font.Bold
                color: card.gradStart
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: card.gameName
                color: "#c5d0de"
                font.pixelSize: 13
                font.weight: Font.Bold
            }
            Text {
                text: card.gameDesc
                color: "#3d4a5c"
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Toggle button
        Rectangle {
            width: optLabel.width + 16; height: 28; radius: 6
            color: card.optimized ? "#0d2818" : "transparent"
            border.color: card.optimized ? "#166534" : Qt.rgba(card.gradStart.r, card.gradStart.g, card.gradStart.b, 0.4)
            border.width: 1

            Text {
                id: optLabel
                anchors.centerIn: parent
                text: card.optimized ? "\u2713" : "Go"
                color: card.optimized ? "#22c55e" : card.gradStart
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.optimize()
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }
}
