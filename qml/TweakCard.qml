import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hone-style optimization card — clean horizontal layout with status badges
Rectangle {
    id: card
    implicitHeight: cardCol.implicitHeight + 24
    radius: 0
    color: cardHover.containsMouse ? "#0e1424" : "transparent"

    // Top border line
    Rectangle {
        anchors.top: parent.top
        width: parent.width; height: 1
        color: "#141a2a"
    }

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
        id: cardHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }

    ColumnLayout {
        id: cardCol
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 6

        // ── Main row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Left status dot
            Rectangle {
                width: 6; height: 6; radius: 3
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 7
                color: card.tweakApplied ? (card.tweakVerified ? "#22c55e" : "#06b6d4")
                     : card.tweakRecommended ? "#f59e0b"
                     : "#1c2333"
            }

            // Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: card.tweakName
                        color: card.tweakApplied ? "#e0f7ff" : "#c5d0de"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // Status badge
                    Rectangle {
                        visible: card.tweakStatus !== "stable"
                        width: statusText.width + 12; height: 20; radius: 4
                        color: {
                            if (card.tweakStatus === "testing") return "#451a03"
                            if (card.tweakStatus === "experimental") return "#3b0764"
                            if (card.tweakStatus === "new") return "#0e2a3d"
                            return "transparent"
                        }
                        border.color: {
                            if (card.tweakStatus === "testing") return "#92400e"
                            if (card.tweakStatus === "experimental") return "#7c3aed"
                            if (card.tweakStatus === "new") return "#164e63"
                            return "transparent"
                        }
                        border.width: 1

                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: {
                                if (card.tweakStatus === "testing") return "Under Testing"
                                if (card.tweakStatus === "experimental") return "Experimental"
                                if (card.tweakStatus === "new") return "New"
                                return ""
                            }
                            color: {
                                if (card.tweakStatus === "testing") return "#fbbf24"
                                if (card.tweakStatus === "experimental") return "#a78bfa"
                                if (card.tweakStatus === "new") return "#22d3ee"
                                return "#4a5568"
                            }
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    // Risk badge
                    Rectangle {
                        visible: card.tweakRisk === "advanced"
                        width: riskText.width + 10; height: 20; radius: 4
                        color: "#451a03"
                        border.color: "#92400e"; border.width: 1

                        Text {
                            id: riskText
                            anchors.centerIn: parent
                            text: "\u26A0 Advanced"
                            color: "#fbbf24"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    // Verified badge
                    Rectangle {
                        visible: card.tweakApplied && card.tweakVerified
                        width: verText.width + 10; height: 20; radius: 4
                        color: "#0d2818"
                        border.color: "#166534"; border.width: 1
                        Text { id: verText; anchors.centerIn: parent; text: "\u2713 Verified"; color: "#22c55e"; font.pixelSize: 9; font.weight: Font.Bold }
                    }

                    // Recommended badge
                    Rectangle {
                        visible: card.tweakRecommended && !card.tweakApplied
                        width: recText.width + 10; height: 20; radius: 4
                        color: "#1c1917"
                        border.color: "#854d0e"; border.width: 1
                        Text { id: recText; anchors.centerIn: parent; text: "\u2605 Recommended"; color: "#fbbf24"; font.pixelSize: 9; font.weight: Font.Bold }
                    }
                }

                Text {
                    text: card.tweakDesc
                    color: "#4a5568"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    lineHeight: 1.3
                }
            }

            // Toggle switch
            Switch {
                id: tweakSwitch
                checked: card.tweakApplied
                Layout.alignment: Qt.AlignVCenter

                indicator: Rectangle {
                    implicitWidth: 42; implicitHeight: 22
                    x: tweakSwitch.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 11
                    color: tweakSwitch.checked ? "#0d3a4a" : "#1a1f30"
                    border.color: tweakSwitch.checked ? "#06b6d4" : "#2d3748"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        x: tweakSwitch.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: tweakSwitch.checked ? "#22d3ee" : "#4a5568"
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }

                onToggled: card.toggled(checked)
            }
        }

        // ── Learn More ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            spacing: 4
            visible: card.tweakLearnMore !== ""

            Text {
                text: card.showLearnMore ? "\u25BE Hide details" : "\u25B8 Learn more"
                color: "#06b6d4"
                font.pixelSize: 10
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.showLearnMore = !card.showLearnMore
                }
            }

            Rectangle {
                visible: card.showLearnMore
                Layout.fillWidth: true
                implicitHeight: lmText.implicitHeight + 14
                radius: 8
                color: "#080c16"
                border.color: "#141a2a"; border.width: 1

                Text {
                    id: lmText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: card.tweakLearnMore
                    color: "#7b8ba3"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    lineHeight: 1.4
                }
            }
        }
    }
}
