import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Dashboard Home Page
Flickable {
    id: dashPage
    contentWidth: width
    contentHeight: mainCol.height + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: "#7c3aed"
            opacity: 0.5
        }
        background: Rectangle { color: "transparent" }
    }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 28
        spacing: 24

        // ── Header Row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Dashboard"
                    color: "#f0eaff"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                Text {
                    text: "System overview and quick actions"
                    color: "#6b5b95"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Mini status badges
            Row {
                spacing: 8

                MiniStatBadge {
                    label: "CPU"
                    value: Math.round(appController.systemMonitor ? appController.systemMonitor.cpuUsage : 0) + "%"
                    accent: "#7c3aed"
                }
                MiniStatBadge {
                    label: "RAM"
                    value: Math.round(appController.systemMonitor ? appController.systemMonitor.ramUsage : 0) + "%"
                    accent: "#d946ef"
                }
                MiniStatBadge {
                    label: "DISK"
                    value: Math.round(appController.systemMonitor ? appController.systemMonitor.storageUsage : 0) + "%"
                    accent: "#06b6d4"
                }
            }
        }

        // ── System Score Overview ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ScoreCard {
                Layout.fillWidth: true
            }
        }

        // ── Stat Cards Row ──
        Flow {
            Layout.fillWidth: true
            spacing: 16

            StatCard {
                cardTitle: "Free RAM"
                value: appController.systemMonitor ? Math.round(100 - appController.systemMonitor.ramUsage) : 50
                subtitle: appController.systemMonitor
                       ? (appController.systemMonitor.ramTotalGb - appController.systemMonitor.ramUsedGb).toFixed(1) + " GB free"
                       : "-- GB free"
                accentStart: "#7c3aed"
                accentEnd: "#a855f7"
            }
            StatCard {
                cardTitle: "Uptime"
                value: {
                    var mins = appController.systemMonitor ? appController.systemMonitor.uptimeMinutes : 0
                    return Math.min(Math.round((mins / 1440.0) * 100), 100); // % of 24h
                }
                subtitle: appController.systemMonitor ? appController.systemMonitor.uptimeText : "--"
                accentStart: "#06b6d4"
                accentEnd: "#22d3ee"
                overrideText: appController.systemMonitor ? appController.systemMonitor.uptimeMinutes + "" : "0"
                overrideLabel: "min"
            }
            StatCard {
                cardTitle: "Memory"
                value: appController.systemMonitor ? Math.round(appController.systemMonitor.ramUsage) : 0
                subtitle: appController.systemMonitor
                       ? appController.systemMonitor.ramUsedGb.toFixed(1) + " / " + appController.systemMonitor.ramTotalGb.toFixed(1) + " GB"
                       : "-- / -- GB"
                accentStart: "#d946ef"
                accentEnd: "#f472b6"
            }
            StatCard {
                cardTitle: "Storage"
                value: appController.systemMonitor ? Math.round(appController.systemMonitor.storageUsage) : 0
                subtitle: appController.systemMonitor
                       ? appController.systemMonitor.storageUsedGb.toFixed(0) + " / " + appController.systemMonitor.storageTotalGb.toFixed(0) + " GB"
                       : "-- / -- GB"
                accentStart: "#10b981"
                accentEnd: "#34d399"
            }
        }

        // ── Middle Row: CPU Graph + System Details ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // CPU Usage card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                radius: 16
                color: "#1a1230"
                border.color: "#2a1f50"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CPU Usage"
                            color: "#f0eaff"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: cpuLabel.width + 16; height: 26; radius: 8
                            color: "#1e1540"
                            Text {
                                id: cpuLabel
                                anchors.centerIn: parent
                                text: Math.round(appController.systemMonitor ? appController.systemMonitor.cpuUsage : 0) + "% CPU"
                                color: "#7c3aed"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // Simple live graph using Canvas
                    Canvas {
                        id: cpuCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        property var history: []
                        property int maxPoints: 60

                        Connections {
                            target: appController.systemMonitor || null
                            function onCpuUsageChanged() {
                                cpuCanvas.history.push(appController.systemMonitor.cpuUsage)
                                if (cpuCanvas.history.length > cpuCanvas.maxPoints)
                                    cpuCanvas.history.shift()
                                cpuCanvas.requestPaint()
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            var w = width, h = height
                            ctx.reset()

                            if (history.length < 2) return

                            // Grid lines
                            ctx.strokeStyle = "#1e1540"
                            ctx.lineWidth = 1
                            for (var g = 0; g < 5; g++) {
                                var gy = h * g / 4
                                ctx.beginPath()
                                ctx.moveTo(0, gy)
                                ctx.lineTo(w, gy)
                                ctx.stroke()
                            }

                            // Fill gradient
                            var grad = ctx.createLinearGradient(0, 0, 0, h)
                            grad.addColorStop(0, "rgba(124, 58, 237, 0.3)")
                            grad.addColorStop(1, "rgba(124, 58, 237, 0.0)")

                            ctx.beginPath()
                            var step = w / (maxPoints - 1)
                            var startIdx = Math.max(0, history.length - maxPoints)
                            var xOff = (maxPoints - history.length + startIdx) * step

                            ctx.moveTo(xOff, h - (history[startIdx] / 100) * h)
                            for (var i = startIdx + 1; i < history.length; i++) {
                                var x = xOff + (i - startIdx) * step
                                var y = h - (history[i] / 100) * h
                                ctx.lineTo(x, y)
                            }
                            // Close fill
                            ctx.lineTo(xOff + (history.length - 1 - startIdx) * step, h)
                            ctx.lineTo(xOff, h)
                            ctx.closePath()
                            ctx.fillStyle = grad
                            ctx.fill()

                            // Line
                            var lineGrad = ctx.createLinearGradient(0, 0, w, 0)
                            lineGrad.addColorStop(0, "#7c3aed")
                            lineGrad.addColorStop(1, "#d946ef")

                            ctx.beginPath()
                            ctx.moveTo(xOff, h - (history[startIdx] / 100) * h)
                            for (i = startIdx + 1; i < history.length; i++) {
                                x = xOff + (i - startIdx) * step
                                y = h - (history[i] / 100) * h
                                ctx.lineTo(x, y)
                            }
                            ctx.strokeStyle = lineGrad
                            ctx.lineWidth = 2.5
                            ctx.stroke()

                            // Glow dot at end
                            if (history.length > 0) {
                                var lastX = xOff + (history.length - 1 - startIdx) * step
                                var lastY = h - (history[history.length - 1] / 100) * h
                                ctx.beginPath()
                                ctx.arc(lastX, lastY, 4, 0, Math.PI * 2)
                                ctx.fillStyle = "#d946ef"
                                ctx.fill()
                                ctx.beginPath()
                                ctx.arc(lastX, lastY, 8, 0, Math.PI * 2)
                                ctx.fillStyle = "rgba(217, 70, 239, 0.3)"
                                ctx.fill()
                            }
                        }
                    }
                }
            }

            // System Details card
            Rectangle {
                Layout.preferredWidth: 280
                Layout.preferredHeight: 220
                radius: 16
                color: "#1a1230"
                border.color: "#2a1f50"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Text {
                        text: "System Details"
                        color: "#f0eaff"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    DetailRow { label: "CPU"; value: appController.cpuName || "Detecting..." }
                    DetailRow { label: "GPU"; value: appController.gpuName || "Detecting..." }
                    DetailRow { label: "RAM"; value: appController.totalRam || "Detecting..." }
                    DetailRow { label: "Uptime"; value: appController.systemMonitor ? appController.systemMonitor.uptimeText : "--" }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ── Hardware Info Row ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: hwCol.height + 32
            radius: 16
            color: "#1a1230"
            border.color: "#2a1f50"
            border.width: 1

            ColumnLayout {
                id: hwCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Hardware Information"
                        color: "#f0eaff"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 60; height: 24; radius: 8
                        color: "#1e1540"
                        Text { anchors.centerIn: parent; text: "Live"; color: "#10b981"; font.pixelSize: 10; font.weight: Font.DemiBold }
                    }
                }

                // Info grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 20
                    rowSpacing: 8

                    HwInfoItem { label: "CPU"; value: appController.cpuName || "Detecting..." }
                    HwInfoItem { label: "GPU"; value: appController.gpuName || "Detecting..." }
                    HwInfoItem { label: "RAM"; value: appController.totalRam || "Detecting..." }
                    HwInfoItem { label: "Storage"; value: appController.diskModel || "Detecting..." }
                    HwInfoItem { label: "OS"; value: appController.osVersion || "Detecting..." }
                    HwInfoItem {
                        label: "Status"
                        value: appController.isAdmin ? "Administrator" : "Standard User"
                        valueColor: appController.isAdmin ? "#10b981" : "#f59e0b"
                    }
                }
            }
        }

        // ── Game Optimization Profiles ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: "Game Optimization Profiles"
                color: "#f0eaff"
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            Flow {
                Layout.fillWidth: true
                spacing: 16

                GameProfileCard {
                    gameName: "Counter-Strike 2"
                    gameDesc: "Max FPS, low latency, competitive settings"
                    gameIcon: "CS2"
                    gradStart: "#f59e0b"
                    gradEnd: "#ef4444"
                    onOptimize: {
                        optimized = !optimized
                        if (optimized) {
                            appController.selectedCategory = "Gaming"
                        }
                    }
                }
                GameProfileCard {
                    gameName: "Fortnite"
                    gameDesc: "Balanced FPS and visual quality"
                    gameIcon: "FN"
                    gradStart: "#7c3aed"
                    gradEnd: "#2563eb"
                    onOptimize: {
                        optimized = !optimized
                    }
                }
                GameProfileCard {
                    gameName: "Valorant"
                    gameDesc: "Low latency, disable overlays, boost network"
                    gameIcon: "VAL"
                    gradStart: "#ef4444"
                    gradEnd: "#dc2626"
                    onOptimize: {
                        optimized = !optimized
                    }
                }
                GameProfileCard {
                    gameName: "Apex Legends"
                    gameDesc: "Smooth FPS, reduce input lag"
                    gameIcon: "APEX"
                    gradStart: "#dc2626"
                    gradEnd: "#f59e0b"
                    onOptimize: {
                        optimized = !optimized
                    }
                }
            }
        }

        // ── Quick Actions ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: qaCol.height + 32
            radius: 16
            color: "#1a1230"
            border.color: "#2a1f50"
            border.width: 1

            ColumnLayout {
                id: qaCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "Quick Actions"
                    color: "#f0eaff"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    ActionPill { text: "\u25B6  Apply All Gaming Tweaks"; onClicked: appController.applyAllGaming() }
                    ActionPill { text: "\u21BA  Restore All Tweaks"; accent: "#ef4444"; onClicked: appController.restoreAll() }
                    ActionPill { text: "\u25C6  Run Benchmark"; onClicked: appController.runBaseline() }
                    ActionPill { text: "\u25CE  Set CS2 Path"; onClicked: cs2PathDialog.open() }
                    ActionPill { text: "\u2726  Clear Temp Files"; onClicked: appController.clearTempFiles() }
                    ActionPill { text: "\u25A3  Flush DNS"; onClicked: appController.flushDns() }
                }
            }
        }

        Item { height: 20 }
    }

    // ── Inline Components ──

    component MiniStatBadge: Rectangle {
        property string label: ""
        property string value: ""
        property color accent: "#7c3aed"

        width: badgeRow.width + 20
        height: 32
        radius: 10
        color: "#1a1230"
        border.color: "#2a1f50"
        border.width: 1

        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 6
            Rectangle {
                width: 6; height: 6; radius: 3
                color: parent.parent.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text { text: parent.parent.label; color: "#6b5b95"; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            Text { text: parent.parent.value; color: "#f0eaff"; font.pixelSize: 11; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    component DetailRow: RowLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        Text { text: parent.label; color: "#6b5b95"; font.pixelSize: 11; Layout.preferredWidth: 60 }
        Text {
            text: parent.value
            color: "#c4b5e0"
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    component HwInfoItem: ColumnLayout {
        property string label: ""
        property string value: ""
        property color valueColor: "#c4b5e0"
        spacing: 2
        Layout.fillWidth: true
        Text { text: parent.label; color: "#6b5b95"; font.pixelSize: 10; font.weight: Font.DemiBold }
        Text { text: parent.value; color: parent.valueColor; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
    }

    component ActionPill: Rectangle {
        property string text: ""
        property color accent: "#7c3aed"
        signal clicked()

        width: pillText.width + 28
        height: 34
        radius: 10
        color: pillHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.15) : "#15102a"
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.3)
        border.width: 1

        Text {
            id: pillText
            anchors.centerIn: parent
            text: parent.text
            color: "#d4b8ff"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: pillHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
