import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: card
    implicitHeight: cardRow.implicitHeight + 28
    radius: 14
    color: applied ? "#121e28" : "#111821"
    border.color: recommended ? "#2a7a9c" : applied ? "#1e4a2e" : "#1c2735"
    border.width: recommended ? 1.5 : 1

    Behavior on border.color { ColorAnimation { duration: 200 } }

    RowLayout {
        id: cardRow
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Status indicator
        Rectangle {
            width: 8; height: 8; radius: 4
            color: applied ? "#5ee87d" : recommended ? "#5ad6ff" : "#3b4a5a"
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 4
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                spacing: 8
                Text {
                    text: name
                    color: "#e6edf6"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                // Category pill
                Rectangle {
                    visible: category !== ""
                    radius: 8
                    color: {
                        switch (category) {
                            case "Gaming":   return "#1a2d3d"
                            case "Latency":  return "#2d1a3d"
                            case "FPS":      return "#1a3d1f"
                            case "Network":  return "#3d2d1a"
                            case "Power":    return "#3d1a1a"
                            case "Services": return "#1a2d2d"
                            case "Visual":   return "#2d2d1a"
                            case "Privacy":  return "#1a2d1a"
                            default:         return "#1a2230"
                        }
                    }
                    implicitWidth: catText.implicitWidth + 14
                    implicitHeight: 20

                    Text {
                        id: catText
                        anchors.centerIn: parent
                        text: category
                        color: {
                            switch (category) {
                                case "Gaming":   return "#5ad6ff"
                                case "Latency":  return "#c77dff"
                                case "FPS":      return "#5ee87d"
                                case "Network":  return "#ffb454"
                                case "Power":    return "#ff6b6b"
                                case "Services": return "#42c6b0"
                                case "Visual":   return "#ffe066"
                                case "Privacy":  return "#76d275"
                                default:         return "#8aa3b8"
                            }
                        }
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            Text {
                text: description
                color: "#6b8299"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 12
                visible: requiresAdmin || recommended

                Text {
                    visible: requiresAdmin
                    text: "🔒 Requires admin"
                    color: "#ff9f43"
                    font.pixelSize: 10
                }
                Text {
                    visible: recommended && !applied
                    text: "★ Recommended"
                    color: "#5ad6ff"
                    font.pixelSize: 10
                }
            }
        }

        // Toggle button
        Button {
            text: applied ? "✓ Active" : "Apply"
            flat: applied
            font.pixelSize: 12
            font.weight: Font.DemiBold
            Material.background: applied ? "transparent" : "#1a3a50"
            Material.foreground: applied ? "#5ee87d" : "#5ad6ff"
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 90

            onClicked: appController.toggleTweak(index)
        }
    }
}
