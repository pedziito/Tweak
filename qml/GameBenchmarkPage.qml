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
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#6366f1"; opacity: 0.5 }
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
                    color: "#e2e8f0"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                Text {
                    text: "Estimated FPS based on your hardware profile"
                    color: "#64748b"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Run button
            Rectangle {
                width: runBtnText.width + 32; height: 40; radius: 12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#6366f1" }
                    GradientStop { position: 1.0; color: "#8b5cf6" }
                }
                opacity: appController.gameBenchmark && appController.gameBenchmark.running ? 0.6 : 1.0

                Text {
                    id: runBtnText
                    anchors.centerIn: parent
                    text: appController.gameBenchmark && appController.gameBenchmark.running
                          ? "\u25CC  Estimating..." : "\u25B6  Run Estimation"
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

        // ── Settings Row: Resolution & Quality Dropdowns ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Resolution dropdown
            ColumnLayout {
                spacing: 4
                Text {
                    text: "Resolution"
                    color: "#94a3b8"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                ComboBox {
                    id: resolutionCombo
                    model: ["1080p", "1440p", "4K"]
                    currentIndex: 0
                    implicitWidth: 140
                    implicitHeight: 36

                    background: Rectangle {
                        radius: 10
                        color: "#111827"
                        border.color: resolutionCombo.pressed ? "#6366f1" : "#1e293b"
                        border.width: 1
                    }

                    contentItem: Text {
                        leftPadding: 12
                        text: resolutionCombo.displayText
                        color: "#e2e8f0"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }

                    popup: Popup {
                        y: resolutionCombo.height + 2
                        width: resolutionCombo.width
                        implicitHeight: contentItem.implicitHeight + 8
                        padding: 4

                        background: Rectangle {
                            radius: 10
                            color: "#0d1117"
                            border.color: "#1e293b"
                            border.width: 1
                        }

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: resolutionCombo.popup.visible ? resolutionCombo.delegateModel : null
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }

                    delegate: ItemDelegate {
                        width: resolutionCombo.width
                        height: 32
                        contentItem: Text {
                            text: modelData
                            color: resolutionCombo.currentIndex === index ? "#a5b4fc" : "#94a3b8"
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                        }
                        background: Rectangle {
                            color: hovered ? "#1e293b" : "transparent"
                            radius: 6
                        }
                    }

                    onCurrentTextChanged: {
                        if (appController.gameBenchmark)
                            appController.gameBenchmark.selectedResolution = currentText
                    }
                }
            }

            // Quality dropdown
            ColumnLayout {
                spacing: 4
                Text {
                    text: "Quality"
                    color: "#94a3b8"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                ComboBox {
                    id: qualityCombo
                    model: ["Low", "Medium", "High", "Ultra"]
                    currentIndex: 1
                    implicitWidth: 140
                    implicitHeight: 36

                    background: Rectangle {
                        radius: 10
                        color: "#111827"
                        border.color: qualityCombo.pressed ? "#6366f1" : "#1e293b"
                        border.width: 1
                    }

                    contentItem: Text {
                        leftPadding: 12
                        text: qualityCombo.displayText
                        color: "#e2e8f0"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }

                    popup: Popup {
                        y: qualityCombo.height + 2
                        width: qualityCombo.width
                        implicitHeight: contentItem.implicitHeight + 8
                        padding: 4

                        background: Rectangle {
                            radius: 10
                            color: "#0d1117"
                            border.color: "#1e293b"
                            border.width: 1
                        }

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: qualityCombo.popup.visible ? qualityCombo.delegateModel : null
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }

                    delegate: ItemDelegate {
                        width: qualityCombo.width
                        height: 32
                        contentItem: Text {
                            text: modelData
                            color: qualityCombo.currentIndex === index ? "#a5b4fc" : "#94a3b8"
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                        }
                        background: Rectangle {
                            color: hovered ? "#1e293b" : "transparent"
                            radius: 6
                        }
                    }

                    onCurrentTextChanged: {
                        if (appController.gameBenchmark)
                            appController.gameBenchmark.selectedQuality = currentText
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Current settings display
            Rectangle {
                width: settingsLabel.width + 24; height: 32; radius: 10
                color: "#111827"
                border.color: "#1e293b"
                border.width: 1

                Text {
                    id: settingsLabel
                    anchors.centerIn: parent
                    text: resolutionCombo.currentText + "  \u00B7  " + qualityCombo.currentText
                    color: "#6366f1"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
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
                metricIcon: "\u25C9"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.networkLatency > 0
                    ? (appController.gameBenchmark.networkLatency < 30 ? "#10b981"
                       : appController.gameBenchmark.networkLatency < 60 ? "#f59e0b" : "#ef4444")
                    : "#64748b"
            }
            MetricCard {
                metricLabel: "Storage Speed"
                metricValue: appController.gameBenchmark
                    ? appController.gameBenchmark.storageSpeed.toFixed(0) + " MB/s"
                    : "-- MB/s"
                metricIcon: "\u25A3"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.storageSpeed > 0
                    ? (appController.gameBenchmark.storageSpeed > 500 ? "#10b981"
                       : appController.gameBenchmark.storageSpeed > 100 ? "#f59e0b" : "#ef4444")
                    : "#64748b"
            }
            MetricCard {
                metricLabel: "System Latency"
                metricValue: appController.gameBenchmark
                    ? appController.gameBenchmark.systemLatencyScore + "/100"
                    : "--/100"
                metricIcon: "\u26A1"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.systemLatencyScore > 0
                    ? (appController.gameBenchmark.systemLatencyScore > 70 ? "#10b981"
                       : appController.gameBenchmark.systemLatencyScore > 40 ? "#f59e0b" : "#ef4444")
                    : "#64748b"
            }
        }

        // ── Game FPS Cards Grid ──
        Text {
            text: "Estimated FPS by Game"
            color: "#e2e8f0"
            font.pixelSize: 17
            font.weight: Font.Bold
            visible: gameRepeater.count > 0
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 14
            rowSpacing: 14
            visible: gameRepeater.count > 0

            Repeater {
                id: gameRepeater
                model: appController.gameBenchmark ? appController.gameBenchmark.gameResults : []

                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 260
                    height: 180
                    radius: 16
                    color: "#0d1117"
                    border.color: "#1e293b"
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

                            // Styled text icon
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 56; height: 56; radius: 14
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: {
                                        var id = game.id || ""
                                        if (id === "cs2") return "#f59e0b"
                                        if (id === "fortnite") return "#6366f1"
                                        return "#ef4444"
                                    }}
                                    GradientStop { position: 1.0; color: {
                                        var id = game.id || ""
                                        if (id === "cs2") return "#ef4444"
                                        if (id === "fortnite") return "#4f46e5"
                                        return "#f59e0b"
                                    }}
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: game.icon || "?"
                                    color: "#ffffff"
                                    font.pixelSize: 16
                                    font.weight: Font.Black
                                    font.letterSpacing: 1
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: ratingText.width + 16; height: 22; radius: 8
                                color: {
                                    var r = game.rating || ""
                                    if (r === "Excellent") return "#0d2818"
                                    if (r === "Great") return "#1a2d15"
                                    if (r === "Good") return "#2d2d15"
                                    if (r === "Playable") return "#2d2015"
                                    return "#2d1515"
                                }
                                Text {
                                    id: ratingText
                                    anchors.centerIn: parent
                                    text: game.rating || "N/A"
                                    color: game.ratingColor || "#94a3b8"
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
                                color: "#e2e8f0"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            Text {
                                text: resolutionCombo.currentText + " \u00B7 " + qualityCombo.currentText
                                color: "#64748b"
                                font.pixelSize: 10
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
                                color: "#111827"

                                Rectangle {
                                    width: parent.width * Math.min((game.avgFps || 0) / 400, 1.0)
                                    height: parent.height
                                    radius: 4
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#6366f1" }
                                        GradientStop { position: 1.0; color: game.ratingColor || "#8b5cf6" }
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

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 64; height: 64; radius: 16
                    color: "#1e293b"

                    Text {
                        anchors.centerIn: parent
                        text: "\u25B6"
                        font.pixelSize: 28
                        color: "#6366f1"
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No estimation data yet"
                    color: "#64748b"
                    font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Select resolution & quality, then click 'Run Estimation'"
                    color: "#475569"
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
        property color accentColor: "#64748b"

        width: 200; height: 90; radius: 14
        color: "#0d1117"
        border.color: "#1e293b"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text { text: parent.parent.metricIcon; font.pixelSize: 22; color: parent.parent.accentColor }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: metricLabel
                    color: "#64748b"
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
            color: "#64748b"
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
