import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Game FPS Estimation & System Benchmark Page
Flickable {
    id: gbPage
    contentWidth: width
    contentHeight: mainCol.height + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#7c3aed"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 28
        spacing: 20

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Game Performance Estimator"
                    color: "#f0eaff"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                Text {
                    text: "Estimated FPS based on your hardware profile"
                    color: "#6b5b95"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Run button
            Rectangle {
                width: runBtnText.width + 32; height: 40; radius: 12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#7c3aed" }
                    GradientStop { position: 1.0; color: "#d946ef" }
                }
                opacity: appController.gameBenchmark && appController.gameBenchmark.running ? 0.6 : 1.0

                Text {
                    id: runBtnText
                    anchors.centerIn: parent
                    text: appController.gameBenchmark && appController.gameBenchmark.running
                          ? "⏳ Estimating..." : "🎮  Run Estimation"
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !(appController.gameBenchmark && appController.gameBenchmark.running)
                    onClicked: appController.runGameBenchmark()
                }
            }
        }

        // ── System Metrics Row ──
        Flow {
            Layout.fillWidth: true
            spacing: 14

            MetricCard {
                metricLabel: "Network Latency"
                metricValue: appController.gameBenchmark
                    ? appController.gameBenchmark.networkLatency.toFixed(1) + " ms"
                    : "-- ms"
                metricIcon: "🌐"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.networkLatency > 0
                    ? (appController.gameBenchmark.networkLatency < 30 ? "#10b981"
                       : appController.gameBenchmark.networkLatency < 60 ? "#f59e0b" : "#ef4444")
                    : "#6b5b95"
            }
            MetricCard {
                metricLabel: "Storage Speed"
                metricValue: appController.gameBenchmark
                    ? appController.gameBenchmark.storageSpeed.toFixed(0) + " MB/s"
                    : "-- MB/s"
                metricIcon: "💾"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.storageSpeed > 0
                    ? (appController.gameBenchmark.storageSpeed > 500 ? "#10b981"
                       : appController.gameBenchmark.storageSpeed > 100 ? "#f59e0b" : "#ef4444")
                    : "#6b5b95"
            }
            MetricCard {
                metricLabel: "System Latency"
                metricValue: appController.gameBenchmark
                    ? appController.gameBenchmark.systemLatencyScore + "/100"
                    : "--/100"
                metricIcon: "⚡"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.systemLatencyScore > 0
                    ? (appController.gameBenchmark.systemLatencyScore > 70 ? "#10b981"
                       : appController.gameBenchmark.systemLatencyScore > 40 ? "#f59e0b" : "#ef4444")
                    : "#6b5b95"
            }
        }

        // ── Game FPS Cards Grid ──
        Text {
            text: "Estimated FPS by Game"
            color: "#f0eaff"
            font.pixelSize: 17
            font.weight: Font.Bold
            visible: gameRepeater.count > 0
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor((gbPage.width - 56) / 320))
            columnSpacing: 14
            rowSpacing: 14
            visible: gameRepeater.count > 0

            Repeater {
                id: gameRepeater
                model: appController.gameBenchmark ? appController.gameBenchmark.gameResults : []

                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 290
                    height: 160
                    radius: 16
                    color: "#1a1230"
                    border.color: "#2a1f50"
                    border.width: 1

                    property var game: modelData

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16

                        // Icon + Rating
                        ColumnLayout {
                            Layout.preferredWidth: 70
                            spacing: 8
                            Layout.alignment: Qt.AlignTop

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: game.icon || "🎮"
                                font.pixelSize: 36
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: ratingText.width + 16; height: 22; radius: 8
                                color: {
                                    var r = game.rating || ""
                                    if (r === "Excellent") return "#152d1a"
                                    if (r === "Great") return "#1a2d15"
                                    if (r === "Good") return "#2d2d15"
                                    if (r === "Playable") return "#2d2015"
                                    return "#2d1515"
                                }
                                Text {
                                    id: ratingText
                                    anchors.centerIn: parent
                                    text: game.rating || "N/A"
                                    color: game.ratingColor || "#8b7db0"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Stats
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: game.name || "Unknown"
                                color: "#f0eaff"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            RowLayout {
                                spacing: 20
                                Layout.fillWidth: true

                                FpsDisplay {
                                    fpsLabel: "AVG FPS"
                                    fpsValue: game.avgFps ? Math.round(game.avgFps) : 0
                                    fpsColor: game.ratingColor || "#10b981"
                                }
                                FpsDisplay {
                                    fpsLabel: "1% LOW"
                                    fpsValue: game.onePercentLow ? Math.round(game.onePercentLow) : 0
                                    fpsColor: "#f59e0b"
                                }
                            }

                            // FPS bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: "#15102a"

                                Rectangle {
                                    width: parent.width * Math.min((game.avgFps || 0) / 400, 1.0)
                                    height: parent.height
                                    radius: 4
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#7c3aed" }
                                        GradientStop { position: 1.0; color: game.ratingColor || "#d946ef" }
                                    }

                                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Empty state ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            visible: gameRepeater.count === 0

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🎮"
                    font.pixelSize: 48
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No estimation data yet"
                    color: "#6b5b95"
                    font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Click 'Run Estimation' to analyze your hardware for popular games"
                    color: "#4a3d70"
                    font.pixelSize: 12
                }
            }
        }

        Item { height: 20 }
    }

    // ── Inline Components ──

    component MetricCard: Rectangle {
        property string metricLabel: ""
        property string metricValue: ""
        property string metricIcon: ""
        property color accentColor: "#6b5b95"

        width: 200; height: 90; radius: 14
        color: "#1a1230"
        border.color: "#2a1f50"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text { text: parent.parent.metricIcon; font.pixelSize: 24 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: metricLabel
                    color: "#6b5b95"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Text {
                    text: metricValue
                    color: accentColor
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }
        }
    }

    component FpsDisplay: ColumnLayout {
        property string fpsLabel: ""
        property int fpsValue: 0
        property color fpsColor: "#10b981"

        spacing: 2
        Text {
            text: fpsLabel
            color: "#6b5b95"
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }
        Text {
            text: fpsValue.toString()
            color: fpsColor
            font.pixelSize: 26
            font.weight: Font.Bold
        }
    }
}
