import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Bento-grid dashboard with asymmetric tile layout
Flickable {
    id: dashRoot
    contentWidth: width
    contentHeight: outerCol.height + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    ColumnLayout {
        id: outerCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 28
        spacing: 16

        // ═══════ HERO ROW: Score + Stats side by side ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // ── Hero Score Card (large, left) ──
            Rectangle {
                Layout.preferredWidth: 380
                Layout.preferredHeight: 260
                radius: 16
                color: "#12172b"
                border.color: "#1c2333"; border.width: 1

                // Gradient accent top edge
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 3; radius: 16
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#06b6d4" }
                        GradientStop { position: 1.0; color: "#0ea5e9" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "System Score"; color: "#7b8ba3"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: tierLbl.width + 14; height: 24; radius: 6
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#06b6d4" }
                                GradientStop { position: 1.0; color: "#0ea5e9" }
                            }
                            Text { id: tierLbl; anchors.centerIn: parent; text: appController.hwScorer ? appController.hwScorer.tier : "—"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }

                    // Big gauges row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 24

                        ColumnLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter
                            CircularGauge {
                                Layout.alignment: Qt.AlignHCenter
                                width: 90; height: 90
                                value: appController.hwScorer ? appController.hwScorer.gamingScore : 0
                                startColor: "#06b6d4"
                                endColor: "#22d3ee"
                                glowColor: "#06b6d4"
                                label: ""
                            }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Gaming"; color: "#7b8ba3"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        }

                        ColumnLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter
                            CircularGauge {
                                Layout.alignment: Qt.AlignHCenter
                                width: 90; height: 90
                                value: appController.hwScorer ? appController.hwScorer.performanceScore : 0
                                startColor: "#f59e0b"
                                endColor: "#fbbf24"
                                glowColor: "#f59e0b"
                                label: ""
                            }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Performance"; color: "#7b8ba3"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        }
                    }

                    // Bottleneck
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28; radius: 6
                        color: "#1a1c26"
                        visible: appController.hwScorer && appController.hwScorer.bottleneck !== ""

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\u26A0"; font.pixelSize: 11; color: "#f59e0b" }
                            Text { text: appController.hwScorer ? appController.hwScorer.bottleneck : ""; font.pixelSize: 10; color: "#fbbf24"; font.weight: Font.DemiBold }
                        }
                    }
                }
            }

            // ── Right column: 2x2 stat tiles ──
            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                columns: 2
                rowSpacing: 16
                columnSpacing: 16

                StatCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cardTitle: "CPU Usage"
                    value: appController.cpuUsage
                    subtitle: appController.cpuName || "Detecting..."
                    accentStart: "#06b6d4"
                    accentEnd: "#22d3ee"
                }

                StatCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cardTitle: "Memory"
                    value: appController.ramUsage
                    subtitle: appController.totalRam || "Detecting..."
                    accentStart: "#8b5cf6"
                    accentEnd: "#a78bfa"
                }

                StatCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cardTitle: "GPU Load"
                    value: appController.gpuUsage
                    subtitle: appController.gpuName || "Detecting..."
                    accentStart: "#10b981"
                    accentEnd: "#34d399"
                }

                StatCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cardTitle: "Disk Activity"
                    value: appController.diskUsage
                    subtitle: appController.diskModel || "Detecting..."
                    accentStart: "#f59e0b"
                    accentEnd: "#fbbf24"
                }
            }
        }

        // ═══════ MIDDLE ROW: Live graph + Hardware info ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // ── Live CPU Graph (wide) ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                radius: 16
                color: "#12172b"
                border.color: "#1c2333"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Usage History"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 48; height: 20; radius: 4
                            color: "#0d2818"; border.color: "#166534"; border.width: 1
                            Text { anchors.centerIn: parent; text: "Live"; color: "#22c55e"; font.pixelSize: 9; font.weight: Font.Bold }
                        }
                    }

                    Canvas {
                        id: cpuGraph
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        property var history: []
                        property int maxPoints: 60

                        Connections {
                            target: appController
                            function onCpuUsageChanged() {
                                cpuGraph.history.push(appController.cpuUsage)
                                if (cpuGraph.history.length > cpuGraph.maxPoints)
                                    cpuGraph.history.shift()
                                cpuGraph.requestPaint()
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            if (history.length < 2) return

                            // Grid lines
                            ctx.strokeStyle = "#1c2333"
                            ctx.lineWidth = 1
                            for (var g = 0; g < 4; g++) {
                                var gy = h * g / 4
                                ctx.beginPath()
                                ctx.moveTo(0, gy)
                                ctx.lineTo(w, gy)
                                ctx.stroke()
                            }

                            // Fill gradient
                            var grad = ctx.createLinearGradient(0, 0, 0, h)
                            grad.addColorStop(0, "rgba(6,182,212,0.25)")
                            grad.addColorStop(1, "rgba(6,182,212,0.0)")
                            ctx.fillStyle = grad
                            ctx.beginPath()
                            ctx.moveTo(0, h)
                            for (var i = 0; i < history.length; i++) {
                                var x = i * w / (maxPoints - 1)
                                var y = h - (history[i] / 100) * h
                                if (i === 0) ctx.lineTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.lineTo((history.length - 1) * w / (maxPoints - 1), h)
                            ctx.closePath()
                            ctx.fill()

                            // Line
                            ctx.beginPath()
                            ctx.strokeStyle = "#06b6d4"
                            ctx.lineWidth = 2
                            ctx.lineJoin = "round"
                            for (var j = 0; j < history.length; j++) {
                                var lx = j * w / (maxPoints - 1)
                                var ly = h - (history[j] / 100) * h
                                if (j === 0) ctx.moveTo(lx, ly)
                                else ctx.lineTo(lx, ly)
                            }
                            ctx.stroke()

                            // Glow dot at end
                            if (history.length > 0) {
                                var ex = (history.length - 1) * w / (maxPoints - 1)
                                var ey = h - (history[history.length - 1] / 100) * h
                                ctx.beginPath()
                                ctx.arc(ex, ey, 4, 0, Math.PI * 2)
                                ctx.fillStyle = "#22d3ee"
                                ctx.fill()
                                ctx.beginPath()
                                ctx.arc(ex, ey, 8, 0, Math.PI * 2)
                                ctx.fillStyle = "rgba(34,211,238,0.2)"
                                ctx.fill()
                            }
                        }
                    }
                }
            }

            // ── Hardware Info Panel (compact) ──
            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 200
                radius: 16
                color: "#12172b"
                border.color: "#1c2333"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Text { text: "Hardware"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 6

                        HwLabel { text: "CPU" }
                        HwValue { text: appController.cpuName || "—" }
                        HwLabel { text: "GPU" }
                        HwValue { text: appController.gpuName || "—" }
                        HwLabel { text: "RAM" }
                        HwValue { text: appController.totalRam || "—" }
                        HwLabel { text: "Storage" }
                        HwValue { text: appController.diskModel || "—" }
                        HwLabel { text: "OS" }
                        HwValue { text: appController.osVersion || "—" }
                    }
                }
            }
        }

        // ═══════ BOTTOM ROW: Quick Actions + Game Profiles side by side ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // ── Quick Actions Grid ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: actionsCol.height + 36
                radius: 16
                color: "#12172b"
                border.color: "#1c2333"; border.width: 1

                ColumnLayout {
                    id: actionsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 10

                    Text { text: "Quick Actions"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8

                        ActionBtn { label: "\u26A1 Apply Recommended"; accent: "#06b6d4"; onClicked: appController.applyAllGaming() }
                        ActionBtn { label: "\u21BA Restore All";       accent: "#f43f5e"; onClicked: appController.restoreAll() }
                        ActionBtn { label: "\u2713 Verify Tweaks";     accent: "#10b981"; onClicked: appController.verifyAllTweaks() }
                        ActionBtn { label: "\u25C6 Run Benchmark";     accent: "#f59e0b"; onClicked: appController.runBaseline() }
                        ActionBtn { label: "\u25CE Set CS2 Path";      accent: "#8b5cf6"; onClicked: cs2PathDialog.open() }
                        ActionBtn { label: "\u2726 Clear Temp";        accent: "#7b8ba3"; onClicked: appController.clearTempFiles() }
                        ActionBtn { label: "\u25C9 Flush DNS";         accent: "#06b6d4"; onClicked: appController.flushDns() }
                    }
                }
            }

            // ── Game Profiles Column ──
            Rectangle {
                Layout.preferredWidth: 360
                Layout.preferredHeight: actionsCol.height + 36
                radius: 16
                color: "#12172b"
                border.color: "#1c2333"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Text { text: "Game Profiles"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        GameProfileCard {
                            Layout.fillWidth: true
                            gameName: "CS2"
                            gameDesc: "Max FPS, competitive"
                            gradStart: "#f59e0b"; gradEnd: "#ef4444"
                            onOptimize: {
                                optimized = !optimized
                                if (optimized) appController.selectedCategory = "Gaming"
                            }
                        }
                        GameProfileCard {
                            Layout.fillWidth: true
                            gameName: "Fortnite"
                            gameDesc: "Balanced FPS"
                            gradStart: "#06b6d4"; gradEnd: "#0ea5e9"
                            onOptimize: optimized = !optimized
                        }
                        GameProfileCard {
                            Layout.fillWidth: true
                            gameName: "Valorant"
                            gameDesc: "Low latency"
                            gradStart: "#ef4444"; gradEnd: "#dc2626"
                            onOptimize: optimized = !optimized
                        }
                        GameProfileCard {
                            Layout.fillWidth: true
                            gameName: "Apex"
                            gameDesc: "Smooth FPS"
                            gradStart: "#dc2626"; gradEnd: "#f59e0b"
                            onOptimize: optimized = !optimized
                        }
                    }
                }
            }
        }

        Item { height: 16 }
    }

    // ── Inline Components ──
    component HwLabel: Text {
        color: "#4a5568"
        font.pixelSize: 10
        font.weight: Font.Bold
        Layout.preferredWidth: 50
    }

    component HwValue: Text {
        color: "#c5d0de"
        font.pixelSize: 11
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    component ActionBtn: Rectangle {
        property string label: ""
        property color accent: "#06b6d4"
        signal clicked()

        Layout.fillWidth: true
        height: 36
        radius: 8
        color: abHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.12) : "#0f1423"
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.2)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: parent.label
            color: parent.accent
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: abHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
