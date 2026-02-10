import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Game Optimization Profile Card
Rectangle {
    id: card
    width: 220
    height: 260
    radius: 16
    color: "#1a1230"
    border.color: hoverArea.containsMouse ? "#7c3aed" : "#2a1f50"
    border.width: 1
    clip: true

    property string gameName: "Game"
    property string gameDesc: "Optimize for competitive play"
    property color gradStart: "#7c3aed"
    property color gradEnd: "#d946ef"
    property string gameIcon: "G"
    property bool optimized: false

    signal optimize()

    // Header gradient
    Rectangle {
        id: headerBg
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 110
        radius: 16
        gradient: Gradient {
            GradientStop { position: 0.0; color: card.gradStart }
            GradientStop { position: 1.0; color: card.gradEnd }
        }

        // Bottom corners fix
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 16
            color: "#1a1230"
        }

        // Game icon large
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -8
            text: card.gameIcon
            font.pixelSize: 22
            font.weight: Font.Black
            font.letterSpacing: 1
            color: "#ffffff"
            opacity: 0.9
        }

        // Subtle pattern overlay
        Rectangle {
            anchors.fill: parent
            radius: 16
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.3) }
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: headerBg.bottom
        anchors.topMargin: -4
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 14
        spacing: 8

        Text {
            text: card.gameName
            color: "#f0eaff"
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        Text {
            text: card.gameDesc
            color: "#6b5b95"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }

        // Optimize button
        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 10
            color: card.optimized ? "#1e3a2e" : "transparent"
            border.color: card.optimized ? "#10b981" : "#7c3aed"
            border.width: 1

            Gradient {
                id: optimizeBtnGrad
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0.486, 0.227, 0.929, 0.15) }
                GradientStop { position: 1.0; color: Qt.rgba(0.850, 0.275, 0.937, 0.15) }
            }
            gradient: card.optimized ? null : optimizeBtnGrad

            Text {
                anchors.centerIn: parent
                text: card.optimized ? "✓ Optimized" : "Optimize"
                color: card.optimized ? "#10b981" : "#d4b8ff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
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
        onClicked: mouse.accepted = false
        onPressed: mouse.accepted = false
        onReleased: mouse.accepted = false
    }

    Behavior on border.color { ColorAnimation { duration: 200 } }
}
