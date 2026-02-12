import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Game FPS / Delay Estimator — estimates FPS & frame-time for popular titles
/// based on detected hardware specs, resolution and quality presets.
Flickable {
    id: fpsPage
    contentWidth: width
    contentHeight: mainCol.implicitHeight + 40
    clip: true; boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    property string selectedRes: appController.gameBenchmark.selectedResolution
    property string selectedQuality: appController.gameBenchmark.selectedQuality

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 28; spacing: 20

        // ═══════ HEADER ═══════
        ColumnLayout {
            spacing: 4
            Text { text: "FPS / Delay Estimator"; color: "#f0f6ff"; font.pixelSize: 26; font.weight: Font.Bold }
            Text { text: "Estimated performance for popular games based on your hardware"; color: "#5a6a7c"; font.pixelSize: 12 }
        }

        // ═══════ HARDWARE SUMMARY BAR ═══════
        Rectangle {
            Layout.fillWidth: true; implicitHeight: hwRow.implicitHeight + 24
            radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

            RowLayout {
                id: hwRow
                anchors.fill: parent; anchors.margins: 14; spacing: 16

                HwChip { label: "CPU"; value: appController.cpuName; score: appController.hwScorer.cpuScore }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#141a2a" }
                HwChip { label: "GPU"; value: appController.gpuName; score: appController.hwScorer.gpuScore }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#141a2a" }
                HwChip { label: "RAM"; value: appController.totalRam; score: appController.hwScorer.ramScore }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#141a2a" }
                HwChip { label: "Tier"; value: appController.hwScorer.tier; score: appController.hwScorer.gamingScore }

                Item { Layout.fillWidth: true }

                // Estimate button
                Rectangle {
                    width: estLabel.width + 36; height: 38; radius: 10
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#f59e0b" }
                        GradientStop { position: 1.0; color: "#fbbf24" }
                    }
                    opacity: appController.gameBenchmark.running ? 0.5 : 1
                    Text {
                        id: estLabel; anchors.centerIn: parent
                        text: appController.gameBenchmark.running ? "Estimating..." : "⚡ Run Estimate"
                        color: "#000"; font.pixelSize: 12; font.weight: Font.Bold
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (!appController.gameBenchmark.running) appController.gameBenchmark.runEstimation()
                    }
                }
            }
        }

        // ═══════ CONTROLS ROW — Resolution + Quality ═══════
        RowLayout {
            Layout.fillWidth: true; spacing: 14

            // Resolution selector
            RowLayout {
                spacing: 8
                Text { text: "Resolution"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Row {
                    spacing: 0
                    Repeater {
                        model: ["1080p", "1440p", "4K"]
                        delegate: Rectangle {
                            width: resLbl.implicitWidth + 24; height: 34; radius: index === 0 ? 8 : (index === 2 ? 8 : 0)
                            color: fpsPage.selectedRes === modelData ? "#f59e0b" : resHover.containsMouse ? "#111827" : "#0c1120"
                            border.color: fpsPage.selectedRes === modelData ? "#f59e0b" : "#141a2a"; border.width: 1
                            Text {
                                id: resLbl; anchors.centerIn: parent; text: modelData
                                color: fpsPage.selectedRes === modelData ? "#000" : "#7b8ba3"
                                font.pixelSize: 12; font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: resHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    fpsPage.selectedRes = modelData
                                    appController.gameBenchmark.selectedResolution = modelData
                                }
                            }
                        }
                    }
                }
            }

            Item { width: 20 }

            // Quality selector
            RowLayout {
                spacing: 8
                Text { text: "Quality"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Row {
                    spacing: 0
                    Repeater {
                        model: ["Low", "Medium", "High", "Ultra"]
                        delegate: Rectangle {
                            width: qLbl.implicitWidth + 24; height: 34; radius: index === 0 ? 8 : (index === 3 ? 8 : 0)
                            color: fpsPage.selectedQuality === modelData ? "#06b6d4" : qHover.containsMouse ? "#111827" : "#0c1120"
                            border.color: fpsPage.selectedQuality === modelData ? "#06b6d4" : "#141a2a"; border.width: 1
                            Text {
                                id: qLbl; anchors.centerIn: parent; text: modelData
                                color: fpsPage.selectedQuality === modelData ? "#000" : "#7b8ba3"
                                font.pixelSize: 12; font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: qHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    fpsPage.selectedQuality = modelData
                                    appController.gameBenchmark.selectedQuality = modelData
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ═══════ NETWORK + STORAGE TESTS ═══════
        RowLayout {
            Layout.fillWidth: true; spacing: 14

            // Ping card
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 70; radius: 12
                color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Rectangle {
                        width: 40; height: 40; radius: 10; color: "#0a1628"; border.color: "#1c2333"; border.width: 1
                        Canvas {
                            anchors.centerIn: parent; width: 18; height: 18
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.strokeStyle = "#06b6d4"; ctx.lineWidth = 1.6; ctx.lineCap = "round"
                                ctx.beginPath(); ctx.arc(9, 14, 7, Math.PI, 0); ctx.stroke()
                                ctx.beginPath(); ctx.arc(9, 14, 4, Math.PI, 0); ctx.stroke()
                                ctx.beginPath(); ctx.arc(9, 14, 1, Math.PI, 0); ctx.stroke()
                            }
                            Component.onCompleted: requestPaint()
                        }
                    }
                    ColumnLayout {
                        spacing: 2; Layout.fillWidth: true
                        Text { text: "Network Latency"; color: "#7b8ba3"; font.pixelSize: 11 }
                        Text {
                            text: appController.gameBenchmark.networkLatency > 0
                                  ? appController.gameBenchmark.networkLatency.toFixed(1) + " ms"
                                  : "Not tested"
                            color: appController.gameBenchmark.networkLatency > 0
                                   ? (appController.gameBenchmark.networkLatency < 30 ? "#22c55e" : appController.gameBenchmark.networkLatency < 60 ? "#f59e0b" : "#ef4444")
                                   : "#4a5568"
                            font.pixelSize: 18; font.weight: Font.Bold
                        }
                    }
                    Rectangle {
                        width: pingBtnLbl.width + 24; height: 32; radius: 8
                        color: "transparent"; border.color: "#1c2333"; border.width: 1
                        Text { id: pingBtnLbl; anchors.centerIn: parent; text: "Test"; color: "#06b6d4"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appController.gameBenchmark.runPingTest() }
                    }
                }
            }

            // Storage speed card
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 70; radius: 12
                color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Rectangle {
                        width: 40; height: 40; radius: 10; color: "#0a1628"; border.color: "#1c2333"; border.width: 1
                        Canvas {
                            anchors.centerIn: parent; width: 18; height: 18
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.strokeStyle = "#a78bfa"; ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                ctx.beginPath(); ctx.roundedRect(2, 4, 14, 10, 2, 2); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(5, 9); ctx.lineTo(8, 7); ctx.lineTo(11, 10); ctx.lineTo(13, 8); ctx.stroke()
                            }
                            Component.onCompleted: requestPaint()
                        }
                    }
                    ColumnLayout {
                        spacing: 2; Layout.fillWidth: true
                        Text { text: "Storage Speed"; color: "#7b8ba3"; font.pixelSize: 11 }
                        Text {
                            text: appController.gameBenchmark.storageSpeed > 0
                                  ? appController.gameBenchmark.storageSpeed.toFixed(0) + " MB/s"
                                  : "Not tested"
                            color: appController.gameBenchmark.storageSpeed > 0
                                   ? (appController.gameBenchmark.storageSpeed > 1000 ? "#22c55e" : appController.gameBenchmark.storageSpeed > 300 ? "#f59e0b" : "#ef4444")
                                   : "#4a5568"
                            font.pixelSize: 18; font.weight: Font.Bold
                        }
                    }
                    Rectangle {
                        width: stoBtnLbl.width + 24; height: 32; radius: 8
                        color: "transparent"; border.color: "#1c2333"; border.width: 1
                        Text { id: stoBtnLbl; anchors.centerIn: parent; text: "Test"; color: "#a78bfa"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appController.gameBenchmark.runStorageTest() }
                    }
                }
            }

            // System latency score
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 70; radius: 12
                color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Rectangle {
                        width: 40; height: 40; radius: 10; color: "#0a1628"; border.color: "#1c2333"; border.width: 1
                        Canvas {
                            anchors.centerIn: parent; width: 18; height: 18
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.strokeStyle = "#f59e0b"; ctx.lineWidth = 1.6; ctx.lineCap = "round"
                                ctx.beginPath(); ctx.arc(9, 9, 7, 0, Math.PI * 2); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(9, 5); ctx.lineTo(9, 9); ctx.lineTo(13, 9); ctx.stroke()
                            }
                            Component.onCompleted: requestPaint()
                        }
                    }
                    ColumnLayout {
                        spacing: 2; Layout.fillWidth: true
                        Text { text: "System Latency Score"; color: "#7b8ba3"; font.pixelSize: 11 }
                        Text {
                            text: appController.gameBenchmark.systemLatencyScore > 0
                                  ? appController.gameBenchmark.systemLatencyScore + " / 100"
                                  : "—"
                            color: {
                                var s = appController.gameBenchmark.systemLatencyScore
                                return s >= 80 ? "#22c55e" : s >= 50 ? "#f59e0b" : s > 0 ? "#ef4444" : "#4a5568"
                            }
                            font.pixelSize: 18; font.weight: Font.Bold
                        }
                    }
                }
            }
        }

        // ═══════ GAME FPS CARDS GRID ═══════
        Text {
            text: appController.gameBenchmark.gameResults.length > 0
                  ? "Estimated Performance  (" + fpsPage.selectedRes + " · " + fpsPage.selectedQuality + ")"
                  : "Press \"Run Estimate\" to see FPS predictions"
            color: appController.gameBenchmark.gameResults.length > 0 ? "#f0f6ff" : "#4a5568"
            font.pixelSize: 14; font.weight: Font.Bold
        }

        Flow {
            Layout.fillWidth: true; spacing: 14

            Repeater {
                model: appController.gameBenchmark.gameResults

                delegate: Rectangle {
                    id: fpsCard
                    width: (mainCol.width - 28) / 3; implicitHeight: fpsInner.implicitHeight + 28
                    radius: 14; color: "#0c1120"; border.color: fpsHover.containsMouse ? modelData.ratingColor : "#141a2a"; border.width: 1; clip: true
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Top accent
                    Rectangle {
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                        height: 3; radius: 14; color: modelData.ratingColor
                    }

                    ColumnLayout {
                        id: fpsInner
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 16; spacing: 12

                        // Game name + badge
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 36; height: 36; radius: 8
                                color: Qt.rgba(0, 0, 0, 0.3); border.color: modelData.ratingColor; border.width: 1
                                Text {
                                    anchors.centerIn: parent; text: modelData.icon
                                    color: modelData.ratingColor; font.pixelSize: 11; font.weight: Font.Black
                                }
                            }
                            ColumnLayout {
                                spacing: 2
                                Text { text: modelData.name; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                                Text { text: fpsPage.selectedRes + " · " + fpsPage.selectedQuality; color: "#4a5568"; font.pixelSize: 10 }
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: ratingLbl.width + 16; height: 22; radius: 6
                                color: Qt.rgba(0, 0, 0, 0.3); border.color: modelData.ratingColor; border.width: 1
                                Text { id: ratingLbl; anchors.centerIn: parent; text: modelData.rating; color: modelData.ratingColor; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                        // FPS numbers
                        RowLayout {
                            Layout.fillWidth: true; spacing: 0

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "AVG FPS"; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.Bold }
                                Text {
                                    text: modelData.avgFps
                                    color: modelData.ratingColor; font.pixelSize: 32; font.weight: Font.Black
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "1% LOW"; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.Bold }
                                Text {
                                    text: modelData.onePercentLow
                                    color: "#c5d0de"; font.pixelSize: 22; font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "FRAME TIME"; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.Bold }
                                Text {
                                    property double ft: modelData.avgFps > 0 ? (1000.0 / modelData.avgFps) : 0
                                    text: ft.toFixed(1) + " ms"
                                    color: ft <= 6.9 ? "#22c55e" : ft <= 16.7 ? "#06b6d4" : ft <= 33.3 ? "#f59e0b" : "#ef4444"
                                    font.pixelSize: 22; font.weight: Font.Bold
                                }
                            }
                        }

                        // Visual FPS bar
                        Rectangle {
                            Layout.fillWidth: true; height: 6; radius: 3; color: "#141a2a"
                            Rectangle {
                                width: {
                                    var pct = Math.min(modelData.avgFps / 300.0, 1.0)
                                    return parent.width * pct
                                }
                                height: parent.height; radius: 3; color: modelData.ratingColor
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }

                        // Delay estimate row
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "Input Delay Est."; color: "#4a5568"; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Text {
                                property double delay: {
                                    var ft = modelData.avgFps > 0 ? (1000.0 / modelData.avgFps) : 50
                                    // Input delay ≈ frame time + system overhead (~4ms GPU pipeline + monitor)
                                    return ft + 4.0
                                }
                                text: delay.toFixed(1) + " ms"
                                color: delay <= 11 ? "#22c55e" : delay <= 21 ? "#06b6d4" : delay <= 38 ? "#f59e0b" : "#ef4444"
                                font.pixelSize: 12; font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea { id: fpsHover; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }

        // ═══════ BOTTLENECK INSIGHT ═══════
        Rectangle {
            Layout.fillWidth: true; implicitHeight: bnCol.implicitHeight + 28
            radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1
            visible: appController.hwScorer.bottleneck !== ""

            ColumnLayout {
                id: bnCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 16; spacing: 10

                RowLayout {
                    spacing: 8
                    Canvas {
                        width: 16; height: 16
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = "#f59e0b"; ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(8, 2); ctx.lineTo(1, 14); ctx.lineTo(15, 14); ctx.closePath()
                            ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(8, 7); ctx.lineTo(8, 10); ctx.stroke()
                            ctx.beginPath(); ctx.arc(8, 12, 0.8, 0, Math.PI*2); ctx.fill()
                        }
                        Component.onCompleted: requestPaint()
                    }
                    Text { text: "Bottleneck Analysis"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                }

                Text {
                    text: appController.hwScorer.bottleneck
                    color: "#7b8ba3"; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true
                }
            }
        }

        Item { height: 20 }
    }

    // ── Inline components ──

    component HwChip: RowLayout {
        property string label: ""
        property string value: ""
        property int score: 0
        spacing: 8
        Rectangle {
            width: 8; height: 8; radius: 4
            color: score >= 80 ? "#22c55e" : score >= 50 ? "#f59e0b" : "#ef4444"
        }
        ColumnLayout {
            spacing: 1
            Text { text: label; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.Bold }
            Text { text: value; color: "#c5d0de"; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.maximumWidth: 200 }
        }
    }
}
