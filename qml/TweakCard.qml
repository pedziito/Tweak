import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: card
    implicitHeight: cardCol.implicitHeight + 28
    radius: 14
    color: tweakApplied ? "#1a1835" : "#0f1a2e"
    border.color: tweakRecommended ? "#3b82f6" : tweakApplied ? "#1e3a2e" : "#1e3a5f"
    border.width: tweakRecommended ? 1.5 : 1

    property string tweakName: ""
    property string tweakDesc: ""
    property string tweakCategory: ""
    property bool tweakEnabled: true
    property bool tweakApplied: false
    property bool tweakRecommended: false
    property string tweakRisk: "safe"
    property string tweakLearnMore: ""
    property bool showLearnMore: false
    signal toggled(bool checked)

    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    ColumnLayout {
        id: cardCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 8

        // ── Top row: indicator + name + badges + switch ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Status indicator dot
            Rectangle {
                width: 8; height: 8; radius: 4
                color: card.tweakApplied ? "#10b981" : card.tweakRecommended ? "#3b82f6" : "#1e3a5f"
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    visible: card.tweakApplied || card.tweakRecommended
                    anchors.centerIn: parent
                    width: 16; height: 16; radius: 8
                    color: "transparent"
                    border.color: parent.color
                    border.width: 1
                    opacity: 0.3
                }
            }

            // Name
            Text {
                text: card.tweakName
                color: "#e2e8f0"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            // Recommended badge
            Rectangle {
                visible: card.tweakRecommended
                radius: 8
                color: "#0f2340"
                implicitWidth: recText.implicitWidth + 14
                implicitHeight: 22

                Text {
                    id: recText
                    anchors.centerIn: parent
                    text: "\u2605 Recommended"
                    color: "#3b82f6"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            // Category pill
            Rectangle {
                visible: card.tweakCategory !== ""
                radius: 8
                color: {
                    switch (card.tweakCategory) {
                        case "Gaming":   return "#0f2340"
                        case "Latency":  return "#2d1540"
                        case "FPS":      return "#152d1a"
                        case "Network":  return "#2d2015"
                        case "Power":    return "#2d1515"
                        case "Services": return "#15252d"
                        case "Visual":   return "#2d2d15"
                        case "Privacy":  return "#152d15"
                        case "Memory":   return "#15152d"
                        default:         return "#0f1a2e"
                    }
                }
                implicitWidth: catText.implicitWidth + 14
                implicitHeight: 22

                Text {
                    id: catText
                    anchors.centerIn: parent
                    text: card.tweakCategory
                    color: {
                        switch (card.tweakCategory) {
                            case "Gaming":   return "#60a5fa"
                            case "Latency":  return "#06b6d4"
                            case "FPS":      return "#10b981"
                            case "Network":  return "#f59e0b"
                            case "Power":    return "#ef4444"
                            case "Services": return "#06b6d4"
                            case "Visual":   return "#fbbf24"
                            case "Privacy":  return "#34d399"
                            case "Memory":   return "#818cf8"
                            default:         return "#94a3b8"
                        }
                    }
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            // Risk badge
            Rectangle {
                visible: card.tweakRisk === "advanced"
                radius: 8
                color: "#2d1515"
                implicitWidth: riskText.implicitWidth + 14
                implicitHeight: 22

                Text {
                    id: riskText
                    anchors.centerIn: parent
                    text: "\u26A0 Advanced"
                    color: "#f59e0b"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            // ── Switch toggle ──
            Switch {
                id: tweakSwitch
                checked: card.tweakApplied
                Layout.alignment: Qt.AlignVCenter

                indicator: Rectangle {
                    implicitWidth: 44
                    implicitHeight: 22
                    x: tweakSwitch.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 11
                    color: tweakSwitch.checked ? "#1e3a2e" : "#0c1524"
                    border.color: tweakSwitch.checked ? "#10b981" : "#1e3a5f"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        x: tweakSwitch.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: tweakSwitch.checked ? "#10b981" : "#64748b"

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
            color: "#94a3b8"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 20
        }

        // ── Learn More expandable details ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            spacing: 4
            visible: card.tweakLearnMore !== ""

            Text {
                text: card.showLearnMore ? "\u25BE Hide details" : "\u25B8 Details"
                color: "#3b82f6"
                font.pixelSize: 10
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.showLearnMore = !card.showLearnMore
                }
            }

            Text {
                visible: card.showLearnMore
                text: card.tweakLearnMore
                color: "#64748b"
                font.pixelSize: 11
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                font.italic: true
            }
        }
    }
}
