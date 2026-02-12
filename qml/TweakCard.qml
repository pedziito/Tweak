import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hone-style optimization card — FIXED HEIGHT for uniform 3-column grid
Rectangle {
    id: card
    implicitHeight: 200
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
    signal toggled(bool checked)

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: cardHover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }

    // Category badge
    Rectangle {
        id: badge; x: 16; y: 16
        width: catText.width + 16; height: 22; radius: 4
        color: "#1a2332"
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
        id: titleText
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: badge.bottom; anchors.topMargin: 10
        anchors.leftMargin: 16; anchors.rightMargin: 16
        text: card.tweakName; color: "#f0f6ff"
        font.pixelSize: 14; font.weight: Font.Bold
        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
    }

    // Description
    Text {
        id: descText
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: titleText.bottom; anchors.topMargin: 6
        anchors.leftMargin: 16; anchors.rightMargin: 16
        text: card.tweakDesc; color: "#5a6a7c"
        font.pixelSize: 11; wrapMode: Text.Wrap; lineHeight: 1.3
        maximumLineCount: 3; elide: Text.ElideRight
    }

    // Warning triangle for risky/testing tweaks (absolute positioned)
    Canvas {
        visible: card.tweakStatus === "testing" || card.tweakRisk === "advanced"
        anchors.left: parent.left; anchors.leftMargin: 16
        anchors.bottom: separator.top; anchors.bottomMargin: 6
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

    // Separator line — always at fixed position from bottom
    Rectangle {
        id: separator
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 16; anchors.rightMargin: 16
        anchors.bottom: bottomRow.top; anchors.bottomMargin: 10
        height: 1; color: "#141a2a"
    }

    // Bottom row: info icon + Activate + toggle — fixed at bottom
    RowLayout {
        id: bottomRow
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.bottomMargin: 14
        spacing: 6

        // Info icon with HOVER TOOLTIP (no dropdown)
        Item {
            width: 16; height: 16

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = infoHover.containsMouse ? "#06b6d4" : "#4a5568"
                    ctx.lineWidth = 1.4; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(8, 8, 6.5, 0, Math.PI * 2); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(8, 5.5); ctx.lineTo(8, 6); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(8, 7.5); ctx.lineTo(8, 11); ctx.stroke()
                }
                Component.onCompleted: requestPaint()
                property bool hv: infoHover.containsMouse
                onHvChanged: requestPaint()
            }

            MouseArea {
                id: infoHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                propagateComposedEvents: true
                onPressed: function(mouse) { mouse.accepted = false }
            }

            // Tooltip popup on hover
            Rectangle {
                id: infoTooltip
                visible: infoHover.containsMouse && card.tweakLearnMore !== ""
                anchors.bottom: parent.top; anchors.bottomMargin: 8
                anchors.left: parent.left
                width: Math.min(tooltipText.implicitWidth + 20, 280)
                height: tooltipText.implicitHeight + 16
                radius: 8; color: "#111827"; border.color: "#1c2333"; border.width: 1
                z: 999

                Text {
                    id: tooltipText
                    anchors.fill: parent; anchors.margins: 10
                    text: card.tweakLearnMore; color: "#9ca3af"
                    font.pixelSize: 11; wrapMode: Text.Wrap; lineHeight: 1.4
                    width: 260
                }
            }

            // Fallback tooltip if no learnMore text
            Rectangle {
                visible: infoHover.containsMouse && card.tweakLearnMore === ""
                anchors.bottom: parent.top; anchors.bottomMargin: 8
                anchors.left: parent.left
                width: fallbackTip.implicitWidth + 20; height: 30
                radius: 6; color: "#111827"; border.color: "#1c2333"; border.width: 1
                z: 999
                Text {
                    id: fallbackTip; anchors.centerIn: parent
                    text: card.tweakDesc; color: "#9ca3af"; font.pixelSize: 11
                    elide: Text.ElideRight; maximumLineCount: 1; width: 240
                }
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "Activate"; color: "#5a6a7c"; font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
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
}
