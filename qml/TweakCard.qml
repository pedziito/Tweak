import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: card
    implicitHeight: cardCol.implicitHeight + 24
    radius: 12
    color: tweakApplied ? "#0f172a" : cardHover.containsMouse ? "#111827" : "#0d1117"
    border.color: tweakApplied ? (tweakVerified ? "#166534" : "#312e81")
                               : tweakRecommended ? "#312e81"
                               : cardHover.containsMouse ? "#1e293b" : "#1a1f2e"
    border.width: 1

    property string tweakName: ""
    property string tweakDesc: ""
    property string tweakCategory: ""
    property bool tweakEnabled: true
    property bool tweakApplied: false
    property bool tweakRecommended: false
    property bool tweakVerified: false
    property string tweakRisk: "safe"
    property string tweakLearnMore: ""
    property bool showLearnMore: false
    signal toggled(bool checked)

    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    // Subtle left accent bar when applied
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        width: 3
        radius: 2
        visible: card.tweakApplied
        color: card.tweakVerified ? "#22c55e" : "#6366f1"
        opacity: 0.8
    }

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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        anchors.leftMargin: 16
        spacing: 6

        // ── Top row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Name
            Text {
                text: card.tweakName
                color: card.tweakApplied ? "#e0e7ff" : "#e2e8f0"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            // Status badges row
            Row {
                spacing: 6

                // Verified badge
                Rectangle {
                    visible: card.tweakApplied && card.tweakVerified
                    radius: 6
                    color: "#052e16"
                    border.color: "#166534"
                    border.width: 1
                    implicitWidth: verifiedText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: verifiedText
                        anchors.centerIn: parent
                        text: "\u2713 Verified"
                        color: "#22c55e"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Applied but not verified
                Rectangle {
                    visible: card.tweakApplied && !card.tweakVerified
                    radius: 6
                    color: "#1e1b4b"
                    border.color: "#312e81"
                    border.width: 1
                    implicitWidth: appliedText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: appliedText
                        anchors.centerIn: parent
                        text: "\u25CF Applied"
                        color: "#818cf8"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Recommended badge
                Rectangle {
                    visible: card.tweakRecommended && !card.tweakApplied
                    radius: 6
                    color: "#172554"
                    border.color: "#1e40af"
                    border.width: 1
                    implicitWidth: recText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: recText
                        anchors.centerIn: parent
                        text: "\u2605 Recommended"
                        color: "#60a5fa"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Category pill
                Rectangle {
                    visible: card.tweakCategory !== ""
                    radius: 6
                    color: {
                        switch (card.tweakCategory) {
                            case "Gaming":   return "#172554"
                            case "Latency":  return "#1e1b4b"
                            case "FPS":      return "#052e16"
                            case "Network":  return "#422006"
                            case "Power":    return "#450a0a"
                            case "Services": return "#164e63"
                            case "Visual":   return "#422006"
                            case "Privacy":  return "#052e16"
                            case "Memory":   return "#1e1b4b"
                            case "Storage":  return "#1c1917"
                            default:         return "#111827"
                        }
                    }
                    implicitWidth: catText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: catText
                        anchors.centerIn: parent
                        text: card.tweakCategory
                        color: {
                            switch (card.tweakCategory) {
                                case "Gaming":   return "#60a5fa"
                                case "Latency":  return "#a78bfa"
                                case "FPS":      return "#34d399"
                                case "Network":  return "#fbbf24"
                                case "Power":    return "#f87171"
                                case "Services": return "#22d3ee"
                                case "Visual":   return "#fbbf24"
                                case "Privacy":  return "#34d399"
                                case "Memory":   return "#a78bfa"
                                case "Storage":  return "#a8a29e"
                                default:         return "#94a3b8"
                            }
                        }
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                // Risk badge
                Rectangle {
                    visible: card.tweakRisk === "advanced"
                    radius: 6
                    color: "#451a03"
                    border.color: "#92400e"
                    border.width: 1
                    implicitWidth: riskText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: riskText
                        anchors.centerIn: parent
                        text: "\u26A0 Advanced"
                        color: "#fbbf24"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }

            // ── Switch toggle ──
            Switch {
                id: tweakSwitch
                checked: card.tweakApplied
                Layout.alignment: Qt.AlignVCenter

                indicator: Rectangle {
                    implicitWidth: 42
                    implicitHeight: 22
                    x: tweakSwitch.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 11
                    color: tweakSwitch.checked ? "#052e16" : "#1e293b"
                    border.color: tweakSwitch.checked ? "#22c55e" : "#374151"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        x: tweakSwitch.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: tweakSwitch.checked ? "#22c55e" : "#64748b"

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                onToggled: card.toggled(checked)
            }
        }

        // ── Description ──
        Text {
            text: card.tweakDesc
            color: "#64748b"
            font.pixelSize: 11
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 0
            lineHeight: 1.3
        }

        // ── Learn More ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: card.tweakLearnMore !== ""

            Text {
                text: card.showLearnMore ? "\u25BE Hide details" : "\u25B8 Learn more"
                color: "#6366f1"
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
                implicitHeight: learnMoreText.implicitHeight + 16
                radius: 8
                color: "#0a0e1a"
                border.color: "#1e293b"
                border.width: 1

                Text {
                    id: learnMoreText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: card.tweakLearnMore
                    color: "#94a3b8"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    lineHeight: 1.4
                }
            }
        }
    }
}
