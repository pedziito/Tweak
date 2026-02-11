import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Game FPS Estimation page — redesigned with cyan/amber theme + new layout
Flickable {
    id: gbPage
    contentWidth: width
    contentHeight: mainCol.height + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 28
        spacing: 20

        // ═══════ HEADER ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 3
                Text {
                    text: "Game Performance Estimator"
                    color: "#f0f6ff"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                Text {
                    text: "Estimated FPS based on your hardware profile"
                    color: "#4a5568"
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Run button
            Rectangle {
                width: runBtnText.width + 28; height: 38; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#06b6d4" }
                    GradientStop { position: 1.0; color: "#0ea5e9" }
                }
                opacity: appController.gameBenchmark && appController.gameBenchmark.running ? 0.5 : 1.0

                Text {
                    id: runBtnText
                    anchors.centerIn: parent
                    text: appController.gameBenchmark && appController.gameBenchmark.running
                          ? "\u25CC  Estimating..." : "\u25B6  Run Estimation"
                    color: "#ffffff"
                    font.pixelSize: 12
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

        // ═══════ SETTINGS ROW ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            ColumnLayout {
                spacing: 4
                Text { text: "Resolution"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
                ComboBox {
                    id: resolutionCombo
                    model: ["1080p", "1440p", "4K"]
                    currentIndex: 0
                    implicitWidth: 130; implicitHeight: 34

                    background: Rectangle { radius: 8; color: "#0c1120"; border.color: resolutionCombo.pressed ? "#06b6d4" : "#141a2a"; border.width: 1 }
                    contentItem: Text { leftPadding: 10; text: resolutionCombo.displayText; color: "#c5d0de"; font.pixelSize: 12; font.weight: Font.DemiBold; verticalAlignment: Text.AlignVCenter }

                    popup: Popup {
                        y: resolutionCombo.height + 2
                        width: resolutionCombo.width
                        implicitHeight: contentItem.implicitHeight + 8
                        padding: 4
                        background: Rectangle { radius: 8; color: "#0b0f17"; border.color: "#141a2a"; border.width: 1 }
                        contentItem: ListView { clip: true; implicitHeight: contentHeight; model: resolutionCombo.popup.visible ? resolutionCombo.delegateModel : null; ScrollIndicator.vertical: ScrollIndicator {} }
                    }

                    delegate: ItemDelegate {
                        width: resolutionCombo.width; height: 30
                        contentItem: Text { text: modelData; color: resolutionCombo.currentIndex === index ? "#22d3ee" : "#7b8ba3"; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
                        background: Rectangle { color: hovered ? "#141a2a" : "transparent"; radius: 4 }
                    }

                    onCurrentTextChanged: {
                        if (appController.gameBenchmark)
                            appController.gameBenchmark.selectedResolution = currentText
                    }
                }
            }

            ColumnLayout {
                spacing: 4
                Text { text: "Quality"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
                ComboBox {
                    id: qualityCombo
                    model: ["Low", "Medium", "High", "Ultra"]
                    currentIndex: 1
                    implicitWidth: 130; implicitHeight: 34

                    background: Rectangle { radius: 8; color: "#0c1120"; border.color: qualityCombo.pressed ? "#06b6d4" : "#141a2a"; border.width: 1 }
                    contentItem: Text { leftPadding: 10; text: qualityCombo.displayText; color: "#c5d0de"; font.pixelSize: 12; font.weight: Font.DemiBold; verticalAlignment: Text.AlignVCenter }

                    popup: Popup {
                        y: qualityCombo.height + 2
                        width: qualityCombo.width
                        implicitHeight: contentItem.implicitHeight + 8
                        padding: 4
                        background: Rectangle { radius: 8; color: "#0b0f17"; border.color: "#141a2a"; border.width: 1 }
                        contentItem: ListView { clip: true; implicitHeight: contentHeight; model: qualityCombo.popup.visible ? qualityCombo.delegateModel : null; ScrollIndicator.vertical: ScrollIndicator {} }
                    }

                    delegate: ItemDelegate {
                        width: qualityCombo.width; height: 30
                        contentItem: Text { text: modelData; color: qualityCombo.currentIndex === index ? "#22d3ee" : "#7b8ba3"; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
                        background: Rectangle { color: hovered ? "#141a2a" : "transparent"; radius: 4 }
                    }

                    onCurrentTextChanged: {
                        if (appController.gameBenchmark)
                            appController.gameBenchmark.selectedQuality = currentText
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Current settings pill
            Rectangle {
                width: settingsLbl.width + 20; height: 30; radius: 8
                color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                Text {
                    id: settingsLbl
                    anchors.centerIn: parent
                    text: resolutionCombo.currentText + "  \u00B7  " + qualityCombo.currentText
                    color: "#06b6d4"
                    font.pixelSize: 11; font.weight: Font.DemiBold
                }
            }
        }

        // ═══════ SYSTEM METRICS ROW ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            MetricCard {
                Layout.fillWidth: true
                metricLabel: "Network Latency"
                metricValue: appController.gameBenchmark ? appController.gameBenchmark.networkLatency.toFixed(1) + " ms" : "-- ms"
                metricIcon: "\u25C9"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.networkLatency > 0
                    ? (appController.gameBenchmark.networkLatency < 30 ? "#10b981"
                       : appController.gameBenchmark.networkLatency < 60 ? "#f59e0b" : "#f43f5e")
                    : "#3d4a5c"
            }
            MetricCard {
                Layout.fillWidth: true
                metricLabel: "Storage Speed"
                metricValue: appController.gameBenchmark ? appController.gameBenchmark.storageSpeed.toFixed(0) + " MB/s" : "-- MB/s"
                metricIcon: "\u25A3"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.storageSpeed > 0
                    ? (appController.gameBenchmark.storageSpeed > 500 ? "#10b981"
                       : appController.gameBenchmark.storageSpeed > 100 ? "#f59e0b" : "#f43f5e")
                    : "#3d4a5c"
            }
            MetricCard {
                Layout.fillWidth: true
                metricLabel: "System Latency"
                metricValue: appController.gameBenchmark ? appController.gameBenchmark.systemLatencyScore + "/100" : "--/100"
                metricIcon: "\u26A1"
                accentColor: appController.gameBenchmark && appController.gameBenchmark.systemLatencyScore > 0
                    ? (appController.gameBenchmark.systemLatencyScore > 70 ? "#10b981"
                       : appController.gameBenchmark.systemLatencyScore > 40 ? "#f59e0b" : "#f43f5e")
                    : "#3d4a5c"
            }
        }

        // ═══════ GAME FPS CARDS ═══════
        Text {
            text: "Estimated FPS by Game"
            color: "#f0f6ff"
            font.pixelSize: 16
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
                    height: 170
                    radius: 14
                    color: "#0c1120"
                    border.color: "#141a2a"; border.width: 1

                    property var game: modelData

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        // Icon + Rating
                        ColumnLayout {
                            Layout.preferredWidth: 60
                            spacing: 6
                            Layout.alignment: Qt.AlignTop

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 48; height: 48; radius: 12
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: {
                                        var id = game.id || ""
                                        if (id === "cs2") return "#f59e0b"
                                        if (id === "fortnite") return "#06b6d4"
                                        return "#f43f5e"
                                    }}
                                    GradientStop { position: 1.0; color: {
                                        var id = game.id || ""
                                        if (id === "cs2") return "#f43f5e"
                                        if (id === "fortnite") return "#0ea5e9"
                                        return "#f59e0b"
                                    }}
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: game.icon || "?"
                                    color: "#ffffff"
                                    font.pixelSize: 14; font.weight: Font.Black; font.letterSpacing: 1
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: ratingT.width + 12; height: 20; radius: 6
                                color: {
                                    var r = game.rating || ""
                                    if (r === "Excellent") return "#0d2818"
                                    if (r === "Great") return "#1a2d15"
                                    if (r === "Good") return "#2d2d15"
                                    if (r === "Playable") return "#2d2015"
                                    return "#2d1515"
                                }
                                Text {
                                    id: ratingT
                                    anchors.centerIn: parent
                                    text: game.rating || "N/A"
                                    color: game.ratingColor || "#7b8ba3"
                                    font.pixelSize: 9; font.weight: Font.Bold
                                }
                            }
                        }

                        // Stats
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Text { text: game.name || "Unknown"; color: "#c5d0de"; font.pixelSize: 15; font.weight: Font.Bold }
                            Text { text: resolutionCombo.currentText + " \u00B7 " + qualityCombo.currentText; color: "#3d4a5c"; font.pixelSize: 10 }

                            RowLayout {
                                spacing: 20; Layout.fillWidth: true
                                FpsDisplay { fpsLabel: "AVG FPS"; fpsValue: game.avgFps ? Math.round(game.avgFps) : 0; fpsColor: game.ratingColor || "#10b981" }
                                FpsDisplay { fpsLabel: "1% LOW";  fpsValue: game.onePercentLow ? Math.round(game.onePercentLow) : 0; fpsColor: "#f59e0b" }
                            }

                            // FPS bar
                            Rectangle {
                                Layout.fillWidth: true; height: 6; radius: 3; color: "#0b0f17"
                                Rectangle {
                                    width: parent.width * Math.min((game.avgFps || 0) / 400, 1.0)
                                    height: parent.height; radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#06b6d4" }
                                        GradientStop { position: 1.0; color: game.ratingColor || "#22d3ee" }
                                    }
                                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════ EMPTY STATE ═══════
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            visible: gameRepeater.count === 0

            Column {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56; height: 56; radius: 14
                    color: "#141a2a"
                    Text { anchors.centerIn: parent; text: "\u25B6"; font.pixelSize: 24; color: "#06b6d4" }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No estimation data yet"; color: "#3d4a5c"; font.pixelSize: 13 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Select resolution & quality, then run estimation"; color: "#2d3748"; font.pixelSize: 11 }
            }
        }

        Item { height: 16 }
    }

    // ── Inline Components ──
    component MetricCard: Rectangle {
        property string metricLabel: ""
        property string metricValue: ""
        property string metricIcon: ""
        property color accentColor: "#3d4a5c"

        height: 80; radius: 12
        color: "#0c1120"; border.color: "#141a2a"; border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text { text: parent.parent.metricIcon; font.pixelSize: 20; color: parent.parent.accentColor }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: metricLabel; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.DemiBold }
                Text { text: metricValue; color: accentColor; font.pixelSize: 17; font.weight: Font.Bold }
            }
        }
    }

    component FpsDisplay: ColumnLayout {
        property string fpsLabel: ""
        property int fpsValue: 0
        property color fpsColor: "#10b981"

        spacing: 1
        Text { text: fpsLabel; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.DemiBold }
        Text { text: fpsValue.toString(); color: fpsColor; font.pixelSize: 22; font.weight: Font.Bold }
    }
}
