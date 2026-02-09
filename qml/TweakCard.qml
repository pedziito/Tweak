import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: card
    implicitHeight: cardRow.implicitHeight + 28
    radius: 14
    color: tweakApplied ? "#1a1835" : "#1a1230"
    border.color: tweakRecommended ? "#7c3aed" : tweakApplied ? "#1e3a2e" : "#2a1f50"
    border.width: tweakRecommended ? 1.5 : 1

    property string tweakName: ""
    property string tweakDesc: ""
    property string tweakCategory: ""
    property bool tweakEnabled: true
    property bool tweakApplied: false
    property bool tweakRecommended: false
    property string tweakRisk: "low"
    signal toggled(bool checked)

    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    RowLayout {
        id: cardRow
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Status indicator
        Rectangle {
            width: 8; height: 8; radius: 4
            color: card.tweakApplied ? "#10b981" : card.tweakRecommended ? "#7c3aed" : "#3b2960"
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 4

            // Glow
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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                spacing: 8
                Text {
                    text: card.tweakName
                    color: "#f0eaff"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                // Category pill
                Rectangle {
                    visible: card.tweakCategory !== ""
                    radius: 8
                    color: {
                        switch (card.tweakCategory) {
                            case "Gaming":   return "#1e1540"
                            case "Latency":  return "#2d1540"
                            case "FPS":      return "#152d1a"
                            case "Network":  return "#2d2015"
                            case "Power":    return "#2d1515"
                            case "Services": return "#15252d"
                            case "Visual":   return "#2d2d15"
                            case "Privacy":  return "#152d15"
                            default:         return "#1a1230"
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
                                case "Gaming":   return "#a78bfa"
                                case "Latency":  return "#d946ef"
                                case "FPS":      return "#10b981"
                                case "Network":  return "#f59e0b"
                                case "Power":    return "#ef4444"
                                case "Services": return "#06b6d4"
                                case "Visual":   return "#fbbf24"
                                case "Privacy":  return "#34d399"
                                default:         return "#8b7db0"
                            }
                        }
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                // Risk badge
                Rectangle {
                    visible: card.tweakRisk === "high"
                    radius: 8
                    color: "#2d1515"
                    implicitWidth: riskText.implicitWidth + 14
                    implicitHeight: 22

                    Text {
                        id: riskText
                        anchors.centerIn: parent
                        text: "⚠ High Risk"
                        color: "#ef4444"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }

            Text {
                text: card.tweakDesc
                color: "#8b7db0"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 12
                visible: card.tweakRecommended && !card.tweakApplied

                Text {
                    text: "★ Recommended"
                    color: "#7c3aed"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        // Toggle button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 90; height: 34; radius: 10
            color: card.tweakApplied ? "#1e3a2e" : "transparent"
            border.color: card.tweakApplied ? "#10b981" : "#7c3aed"
            border.width: 1

            Gradient {
                id: applyBtnGrad
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0.486, 0.227, 0.929, 0.15) }
                GradientStop { position: 1.0; color: Qt.rgba(0.850, 0.275, 0.937, 0.15) }
            }
            gradient: card.tweakApplied ? null : applyBtnGrad

            Text {
                anchors.centerIn: parent
                text: card.tweakApplied ? "✓ Active" : "Apply"
                color: card.tweakApplied ? "#10b981" : "#d4b8ff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.toggled(!card.tweakApplied)
            }
        }
    }
}
