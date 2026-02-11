import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hone-style optimization card — tall card for 3-column grid
Rectangle {
    id: card
    implicitHeight: cardCol.implicitHeight + 32
    radius: 12
    color: cardHover.containsMouse ? "#111827" : "#0c1120"
    border.color: "#141a2a"; border.width: 1
    clip: true

    property string tweakName: ""
    property string tweakDesc: ""
    property string tweakCategory: ""
    property bool tweakEnabled: true
    property bool tweakApplied: false
    property bool tweakRecommended: false
    property bool tweakVerified: false
    property string tweakRisk: "safe"
    property string tweakLearnMore: ""
    property string tweakStatus: "stable"
    property bool showLearnMore: false
    signal toggled(bool checked)

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: cardHover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }

    ColumnLayout {
        id: cardCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 16; spacing: 8

        // Category badge (colored like Hone)
        Rectangle {
            width: catText.width + 16; height: 22; radius: 4
            color: {
                if (card.tweakCategory === "Privacy") return "#1a2332"
                if (card.tweakCategory === "Network") return "#1a2332"
                if (card.tweakCategory === "Gaming") return "#1a2332"
                if (card.tweakCategory === "Power") return "#1a2332"
                if (card.tweakCategory === "System") return "#1a2332"
                if (card.tweakCategory === "Memory") return "#1a2332"
                if (card.tweakCategory === "Storage") return "#1a2332"
                if (card.tweakCategory === "Visual") return "#1a2332"
                return "#1a2332"
            }
            border.color: {
                if (card.tweakCategory === "Gaming") return "#06b6d4"
                if (card.tweakCategory === "Network") return "#06b6d4"
                if (card.tweakCategory === "Privacy") return "#22c55e"
                if (card.tweakCategory === "Power") return "#f59e0b"
                if (card.tweakCategory === "System") return "#8b5cf6"
                if (card.tweakCategory === "Memory") return "#06b6d4"
                if (card.tweakCategory === "Storage") return "#06b6d4"
                if (card.tweakCategory === "Visual") return "#f59e0b"
                return "#4a5568"
            }
            border.width: 1

            Text {
                id: catText; anchors.centerIn: parent
                text: card.tweakCategory
                color: parent.border.color
                font.pixelSize: 10; font.weight: Font.Bold
            }
        }

        // Title
        Text {
            text: card.tweakName; color: "#f0f6ff"
            font.pixelSize: 14; font.weight: Font.Bold
            wrapMode: Text.Wrap; Layout.fillWidth: true
        }

        // Description
        Text {
            text: card.tweakDesc; color: "#5a6a7c"
            font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true
            lineHeight: 1.3
            maximumLineCount: 3; elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }

        // Warning triangle for risky/testing tweaks
        Canvas {
            visible: card.tweakStatus === "testing" || card.tweakRisk === "advanced"
            width: 18; height: 18
            onPaint: {
                var ctx = getContext("2d"); ctx.reset()
                ctx.strokeStyle = "#f59e0b"; ctx.fillStyle = "#f59e0b"
                ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"
                ctx.beginPath(); ctx.moveTo(9, 2); ctx.lineTo(17, 16); ctx.lineTo(1, 16); ctx.closePath(); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(9, 7); ctx.lineTo(9, 11); ctx.stroke()
                ctx.beginPath(); ctx.arc(9, 13.5, 1, 0, Math.PI * 2); ctx.fill()
            }
            Component.onCompleted: requestPaint()
        }

        // Bottom row: action icons + Activate toggle
        Rectangle {
            Layout.fillWidth: true; height: 1; color: "#141a2a"
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6

            // Info icon
            Canvas {
                width: 16; height: 16
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = "#4a5568"; ctx.lineWidth = 1.4; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(8, 8, 6.5, 0, Math.PI * 2); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(8, 5.5); ctx.lineTo(8, 6); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(8, 7.5); ctx.lineTo(8, 11); ctx.stroke()
                }
                Component.onCompleted: requestPaint()
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: card.showLearnMore = !card.showLearnMore
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Activate"; color: "#5a6a7c"; font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }

            Switch {
                id: tweakSwitch; checked: card.tweakApplied
                indicator: Rectangle {
                    implicitWidth: 40; implicitHeight: 20; radius: 10
                    x: tweakSwitch.leftPadding; y: parent.height / 2 - height / 2
                    color: tweakSwitch.checked ? "#0d3a4a" : "#1a1f30"
                    border.color: tweakSwitch.checked ? "#06b6d4" : "#2d3748"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Rectangle {
                        x: tweakSwitch.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: tweakSwitch.checked ? "#22d3ee" : "#4a5568"
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
                onToggled: card.toggled(checked)
            }
        }

        // Learn more expandable
        Rectangle {
            visible: card.showLearnMore && card.tweakLearnMore !== ""
            Layout.fillWidth: true; implicitHeight: lmText.implicitHeight + 14
            radius: 8; color: "#080c16"; border.color: "#141a2a"; border.width: 1
            Text {
                id: lmText; anchors.fill: parent; anchors.margins: 8
                text: card.tweakLearnMore; color: "#7b8ba3"; font.pixelSize: 11; wrapMode: Text.Wrap; lineHeight: 1.4
            }
        }
    }
}
