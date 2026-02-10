import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hardware Score Overview Card with dual circular gauges
Rectangle {
    id: scoreCard
    implicitHeight: scoreCol.height + 32
    radius: 16
    color: "#1a1230"
    border.color: "#2a1f50"
    border.width: 1

    ColumnLayout {
        id: scoreCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "System Score"
                color: "#f0eaff"
                font.pixelSize: 17
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: tierLabel.width + 16; height: 26; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#7c3aed" }
                    GradientStop { position: 1.0; color: "#d946ef" }
                }
                opacity: 0.8
                Text {
                    id: tierLabel
                    anchors.centerIn: parent
                    text: appController.hwScorer ? appController.hwScorer.tier : "Unknown"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
        }

        // Gauges row
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            Layout.alignment: Qt.AlignHCenter

            // Gaming Score
            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                CircularGauge {
                    Layout.alignment: Qt.AlignHCenter
                    width: 100; height: 100
                    value: appController.hwScorer ? appController.hwScorer.gamingScore : 0
                    startColor: "#7c3aed"
                    endColor: "#d946ef"
                    glowColor: "#7c3aed"
                    label: ""
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Gaming Score"
                    color: "#8b7db0"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            // Performance Score
            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                CircularGauge {
                    Layout.alignment: Qt.AlignHCenter
                    width: 100; height: 100
                    value: appController.hwScorer ? appController.hwScorer.performanceScore : 0
                    startColor: "#06b6d4"
                    endColor: "#10b981"
                    glowColor: "#06b6d4"
                    label: ""
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Performance Score"
                    color: "#8b7db0"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        // Bottleneck indicator
        Rectangle {
            Layout.fillWidth: true
            height: bnRow.height + 16
            radius: 10
            color: "#15102a"
            visible: appController.hwScorer && appController.hwScorer.bottleneck !== ""

            RowLayout {
                id: bnRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                spacing: 8

                Text { text: "⚠"; font.pixelSize: 14 }
                Text {
                    text: "Bottleneck: " + (appController.hwScorer ? appController.hwScorer.bottleneck : "")
                    color: "#f59e0b"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }
            }
        }

        // Sub-scores
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            SubScoreBar { barLabel: "CPU"; barValue: appController.hwScorer ? appController.hwScorer.cpuScore : 0; barColor: "#7c3aed" }
            SubScoreBar { barLabel: "GPU"; barValue: appController.hwScorer ? appController.hwScorer.gpuScore : 0; barColor: "#d946ef" }
            SubScoreBar { barLabel: "RAM"; barValue: appController.hwScorer ? appController.hwScorer.ramScore : 0; barColor: "#06b6d4" }
            SubScoreBar { barLabel: "Storage"; barValue: appController.hwScorer ? appController.hwScorer.storageScore : 0; barColor: "#10b981" }
        }

        // Insights
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: appController.hwScorer && appController.hwScorer.insights.length > 0

            Text {
                text: "Insights"
                color: "#f0eaff"
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Repeater {
                model: appController.hwScorer ? appController.hwScorer.insights : []

                Rectangle {
                    Layout.fillWidth: true
                    height: insightRow.height + 12
                    radius: 8
                    color: {
                        var s = modelData.severity || "info"
                        if (s === "good") return "#0d1f17"
                        if (s === "warning") return "#1f1a0d"
                        if (s === "critical") return "#1f0d0d"
                        return "#15102a"
                    }
                    border.color: {
                        var s = modelData.severity || "info"
                        if (s === "good") return "#10b981"
                        if (s === "warning") return "#f59e0b"
                        if (s === "critical") return "#ef4444"
                        return "#2a1f50"
                    }
                    border.width: 1

                    RowLayout {
                        id: insightRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: {
                                var s = modelData.severity || "info"
                                if (s === "good") return "✓"
                                if (s === "warning") return "⚠"
                                if (s === "critical") return "✕"
                                return "ℹ"
                            }
                            font.pixelSize: 12
                        }
                        Text {
                            text: modelData.text || ""
                            color: "#c4b5e0"
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // ── SubScoreBar component ──
    component SubScoreBar: RowLayout {
        property string barLabel: ""
        property int barValue: 0
        property color barColor: "#7c3aed"

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: barLabel
            color: "#6b5b95"
            font.pixelSize: 11
            Layout.preferredWidth: 50
        }

        Rectangle {
            Layout.fillWidth: true
            height: 10
            radius: 5
            color: "#15102a"

            Rectangle {
                width: parent.width * Math.min(barValue / 100.0, 1.0)
                height: parent.height
                radius: 5
                color: barColor

                Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            text: barValue.toString()
            color: "#c4b5e0"
            font.pixelSize: 11
            font.weight: Font.Bold
            Layout.preferredWidth: 28
            horizontalAlignment: Text.AlignRight
        }
    }
}
