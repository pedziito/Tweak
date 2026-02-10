import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Game Optimization Profile Card
Rectangle {
    id: card
    width: 220
    height: 260
    radius: 16
    color: "#0f1a2e"
    border.color: hoverArea.containsMouse ? "#3b82f6" : "#1e3a5f"
    border.width: 1
    clip: true

    property string gameName: "Game"
    property string gameDesc: "Optimize for competitive play"
    property color gradStart: "#3b82f6"
    property color gradEnd: "#06b6d4"
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
            color: "#0f1a2e"
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
            color: "#e2e8f0"
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        Text {
            text: card.gameDesc
            color: "#64748b"
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
            border.color: card.optimized ? "#10b981" : "#3b82f6"
            border.width: 1

            Gradient {
                id: optimizeBtnGrad
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0.231, 0.510, 0.965, 0.15) }
                GradientStop { position: 1.0; color: Qt.rgba(0.024, 0.714, 0.831, 0.15) }
            }
            gradient: card.optimized ? null : optimizeBtnGrad

            Text {
                anchors.centerIn: parent
                text: card.optimized ? "✓ Optimized" : "Optimize"
                color: card.optimized ? "#10b981" : "#93c5fd"
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
