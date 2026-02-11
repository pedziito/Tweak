import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Flickable {
    id: dashRoot
    contentWidth: width
    contentHeight: outerCol.implicitHeight + 56
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
        spacing: 20

        // ═══════ TOP STATS ROW ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            DashStatCard {
                Layout.fillWidth: true
                label: "Optimizations Active"
                value: appController.appliedCount
                accentColor: "#06b6d4"
                buttonText: "View Optimizations"
                onButtonClicked: root.currentPage = 1
            }
            DashStatCard {
                Layout.fillWidth: true
                label: "Recommended Available"
                value: appController.recommendedCount
                accentColor: "#f59e0b"
                buttonText: "View Recommended"
                onButtonClicked: root.currentPage = 1
            }
            DashStatCard {
                Layout.fillWidth: true
                label: "Total Tweaks"
                value: appController.tweakModel.rowCount()
                accentColor: "#8b5cf6"
                buttonText: "View All"
                onButtonClicked: root.currentPage = 1
            }
        }

        // ═══════ MAIN: Left (optimizations) + Right (gauges + shortcuts) ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // LEFT: Optimizations list
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 300
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12

                    Row {
                        spacing: 8
                        Rectangle { width: 8; height: 8; radius: 4; color: "#06b6d4"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Your Optimizations"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: manageLabel.width + 20; height: 30; radius: 8
                        color: "#0f1423"; border.color: "#1c2333"; border.width: 1

                        Text {
                            id: manageLabel
                            anchors.centerIn: parent
                            text: "Manage Presets"
                            color: "#7b8ba3"; font.pixelSize: 11; font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = 1
                        }
                    }
                }

                // Optimizations list (first 8)
                Repeater {
                    model: Math.min(8, appController.tweakModel.rowCount())

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        color: optHover.containsMouse ? "#0e1424" : "transparent"

                        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#141a2a" }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4; anchors.rightMargin: 12
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: appController.tweakModel.data(appController.tweakModel.index(index, 0), 258) || ""
                                    color: "#e0f7ff"; font.pixelSize: 13; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: {
                                        var desc = appController.tweakModel.data(appController.tweakModel.index(index, 0), 259) || ""
                                        return desc.length > 60 ? desc.substring(0, 57) + "..." : desc
                                    }
                                    color: "#4a5568"; font.pixelSize: 11
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }

                            // Status badge
                            Rectangle {
                                visible: {
                                    var s = appController.tweakModel.data(appController.tweakModel.index(index, 0), 267) || "stable"
                                    return s !== "stable"
                                }
                                width: sBadgeText.width + 12; height: 20; radius: 4
                                color: {
                                    var s = appController.tweakModel.data(appController.tweakModel.index(index, 0), 267) || "stable"
                                    if (s === "testing") return "#451a03"
                                    if (s === "experimental") return "#3b0764"
                                    if (s === "new") return "#0e2a3d"
                                    return "transparent"
                                }
                                border.color: {
                                    var s = appController.tweakModel.data(appController.tweakModel.index(index, 0), 267) || "stable"
                                    if (s === "testing") return "#92400e"
                                    if (s === "experimental") return "#7c3aed"
                                    if (s === "new") return "#164e63"
                                    return "transparent"
                                }
                                border.width: 1

                                Text {
                                    id: sBadgeText
                                    anchors.centerIn: parent
                                    text: {
                                        var s = appController.tweakModel.data(appController.tweakModel.index(index, 0), 267) || "stable"
                                        if (s === "testing") return "Under Testing"
                                        if (s === "experimental") return "Experimental"
                                        if (s === "new") return "New"
                                        return ""
                                    }
                                    color: {
                                        var s = appController.tweakModel.data(appController.tweakModel.index(index, 0), 267) || "stable"
                                        if (s === "testing") return "#fbbf24"
                                        if (s === "experimental") return "#a78bfa"
                                        if (s === "new") return "#22d3ee"
                                        return "#4a5568"
                                    }
                                    font.pixelSize: 9; font.weight: Font.Bold
                                }
                            }

                            // Toggle
                            Switch {
                                id: dashSwitch
                                checked: appController.tweakModel.data(appController.tweakModel.index(index, 0), 262) || false

                                indicator: Rectangle {
                                    implicitWidth: 42; implicitHeight: 22
                                    x: dashSwitch.leftPadding; y: parent.height / 2 - height / 2
                                    radius: 11
                                    color: dashSwitch.checked ? "#0d3a4a" : "#1a1f30"
                                    border.color: dashSwitch.checked ? "#06b6d4" : "#2d3748"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        x: dashSwitch.checked ? parent.width - width - 3 : 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16; height: 16; radius: 8
                                        color: dashSwitch.checked ? "#22d3ee" : "#4a5568"
                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                }
                                onToggled: appController.toggleTweak(index)
                            }
                        }

                        MouseArea {
                            id: optHover
                            anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
                            onClicked: function(mouse) { mouse.accepted = false }
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                // View all link
                Rectangle {
                    Layout.fillWidth: true; Layout.topMargin: 8
                    height: 36; radius: 8
                    color: viewAllHover.containsMouse ? "#0e1424" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "View all " + appController.tweakModel.rowCount() + " optimizations"
                        color: "#06b6d4"; font.pixelSize: 12; font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: viewAllHover
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPage = 1
                    }
                }
            }

            // RIGHT: Gauges + shortcuts
            ColumnLayout {
                Layout.preferredWidth: 380
                Layout.minimumWidth: 280
                Layout.maximumWidth: 440
                spacing: 16

                // CPU usage card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    radius: 14; color: "#0c1120"
                    border.color: "#141a2a"; border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 16; spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 6

                            Text { text: "CPU USAGE"; color: "#7b8ba3"; font.pixelSize: 11; font.weight: Font.Bold }

                            Canvas {
                                id: cpuMiniGraph
                                Layout.fillWidth: true; Layout.fillHeight: true

                                property var history: []
                                property int maxPoints: 40

                                Connections {
                                    target: appController.systemMonitor
                                    function onUpdated() {
                                        cpuMiniGraph.history.push(appController.systemMonitor.cpuUsage)
                                        if (cpuMiniGraph.history.length > cpuMiniGraph.maxPoints) cpuMiniGraph.history.shift()
                                        cpuMiniGraph.requestPaint()
                                    }
                                }

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    var w = width, h = height
                                    if (history.length < 2) return

                                    ctx.strokeStyle = "#141a2a"; ctx.lineWidth = 1
                                    for (var g = 0; g < 3; g++) {
                                        var gy = h * g / 3
                                        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke()
                                    }

                                    var grad = ctx.createLinearGradient(0, 0, 0, h)
                                    grad.addColorStop(0, "rgba(34,197,94,0.2)")
                                    grad.addColorStop(1, "rgba(34,197,94,0.0)")
                                    ctx.fillStyle = grad
                                    ctx.beginPath(); ctx.moveTo(0, h)
                                    for (var i = 0; i < history.length; i++) {
                                        ctx.lineTo(i * w / (maxPoints - 1), h - (history[i] / 100) * h)
                                    }
                                    ctx.lineTo((history.length - 1) * w / (maxPoints - 1), h)
                                    ctx.closePath(); ctx.fill()

                                    ctx.beginPath(); ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 2; ctx.lineJoin = "round"
                                    for (var j = 0; j < history.length; j++) {
                                        var lx = j * w / (maxPoints - 1)
                                        var ly = h - (history[j] / 100) * h
                                        if (j === 0) ctx.moveTo(lx, ly); else ctx.lineTo(lx, ly)
                                    }
                                    ctx.stroke()

                                    if (history.length > 0) {
                                        var ex = (history.length - 1) * w / (maxPoints - 1)
                                        var ey = h - (history[history.length - 1] / 100) * h
                                        ctx.beginPath(); ctx.arc(ex, ey, 4, 0, Math.PI * 2); ctx.fillStyle = "#22c55e"; ctx.fill()
                                    }
                                }
                            }
                        }

                        CircularGauge {
                            width: 100; height: 100; Layout.alignment: Qt.AlignVCenter
                            value: appController.systemMonitor.cpuUsage
                            startColor: "#22c55e"; endColor: "#4ade80"
                            lineWidth: 8; label: ""
                        }
                    }
                }

                // Disk + RAM gauges
                RowLayout {
                    Layout.fillWidth: true; spacing: 14

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 140
                        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 8
                            Text { text: "DISK USAGE"; color: "#7b8ba3"; font.pixelSize: 10; font.weight: Font.Bold }
                            CircularGauge {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80; height: 80
                                value: appController.systemMonitor.storageUsage
                                startColor: "#06b6d4"; endColor: "#22d3ee"; lineWidth: 7; label: ""
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 140
                        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 8
                            Text { text: "RAM USAGE"; color: "#7b8ba3"; font.pixelSize: 10; font.weight: Font.Bold }
                            CircularGauge {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80; height: 80
                                value: appController.systemMonitor.ramUsage
                                startColor: "#f59e0b"; endColor: "#fbbf24"; lineWidth: 7; label: ""
                            }
                        }
                    }
                }

                // Shortcuts
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: shortcutsCol.implicitHeight + 32
                    radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                    ColumnLayout {
                        id: shortcutsCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 16; spacing: 12

                        Text { text: "Quick Actions"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }

                        GridLayout {
                            Layout.fillWidth: true; columns: 3
                            rowSpacing: 10; columnSpacing: 10

                            ShortcutBtn { label: "Apply All"; accent: "#06b6d4"; onClicked: appController.applyAllGaming() }
                            ShortcutBtn { label: "Restore";   accent: "#f43f5e"; onClicked: appController.restoreAll() }
                            ShortcutBtn { label: "Verify";    accent: "#22c55e"; onClicked: appController.verifyAllTweaks() }
                        }
                    }
                }
            }
        }

        // ═══════ BOTTOM: Hardware + Score + Games ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Hardware info
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: hwCol.implicitHeight + 36
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    id: hwCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 18; spacing: 10

                    Text { text: "System Hardware"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }

                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 16; rowSpacing: 8

                        HwLabel { text: "CPU" }
                        HwValue { text: appController.cpuName || "Detecting..." }
                        HwLabel { text: "GPU" }
                        HwValue { text: appController.gpuName || "Detecting..." }
                        HwLabel { text: "RAM" }
                        HwValue { text: appController.totalRam || "Detecting..." }
                        HwLabel { text: "Storage" }
                        HwValue { text: appController.diskModel || "Detecting..." }
                        HwLabel { text: "OS" }
                        HwValue { text: appController.osVersion || "Detecting..." }
                    }
                }
            }

            // Score
            Rectangle {
                Layout.preferredWidth: 260
                implicitHeight: hwCol.implicitHeight + 36
                Layout.minimumHeight: implicitHeight
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                Rectangle {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    height: 3; radius: 14
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#06b6d4" }
                        GradientStop { position: 1.0; color: "#0ea5e9" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 12

                    Text { text: "System Score"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 20

                        CircularGauge {
                            width: 70; height: 70; Layout.alignment: Qt.AlignVCenter
                            value: appController.hwScorer ? appController.hwScorer.gamingScore : 0
                            startColor: "#06b6d4"; endColor: "#22d3ee"; lineWidth: 6; label: ""
                        }

                        ColumnLayout {
                            spacing: 4
                            Text { text: "Gaming"; color: "#7b8ba3"; font.pixelSize: 11 }
                            Text {
                                text: appController.hwScorer ? appController.hwScorer.tier : "N/A"
                                color: "#22d3ee"; font.pixelSize: 16; font.weight: Font.Bold
                            }
                            Text {
                                visible: appController.hwScorer && appController.hwScorer.bottleneck !== ""
                                text: appController.hwScorer ? appController.hwScorer.bottleneck : ""
                                color: "#fbbf24"; font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            // Game profiles
            Rectangle {
                Layout.preferredWidth: 340
                implicitHeight: hwCol.implicitHeight + 36
                Layout.minimumHeight: implicitHeight
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 10

                    Text { text: "Game Profiles"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }

                    GridLayout {
                        Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 8

                        GameProfileCard { Layout.fillWidth: true; gameName: "CS2"; gameDesc: "Max FPS"; gradStart: "#f59e0b"; gradEnd: "#ef4444"; onOptimize: optimized = !optimized }
                        GameProfileCard { Layout.fillWidth: true; gameName: "Fortnite"; gameDesc: "Balanced"; gradStart: "#06b6d4"; gradEnd: "#0ea5e9"; onOptimize: optimized = !optimized }
                        GameProfileCard { Layout.fillWidth: true; gameName: "Valorant"; gameDesc: "Low latency"; gradStart: "#ef4444"; gradEnd: "#dc2626"; onOptimize: optimized = !optimized }
                        GameProfileCard { Layout.fillWidth: true; gameName: "Apex"; gameDesc: "Smooth FPS"; gradStart: "#dc2626"; gradEnd: "#f59e0b"; onOptimize: optimized = !optimized }
                    }
                }
            }
        }

        Item { height: 16 }
    }

    // ── Inline Components ──
    component HwLabel: Text {
        color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold; Layout.preferredWidth: 50
    }
    component HwValue: Text {
        color: "#c5d0de"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true
    }

    component DashStatCard: Rectangle {
        property string label: ""
        property int value: 0
        property color accentColor: "#06b6d4"
        property string buttonText: ""
        signal buttonClicked()

        Layout.fillWidth: true
        height: 110; radius: 14
        color: "#0c1120"; border.color: "#141a2a"; border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 6

            Rectangle {
                width: 8; height: 8; radius: 4; color: accentColor
            }

            Text {
                text: value; color: "#f0f6ff"
                font.pixelSize: 28; font.weight: Font.Bold
            }
            Text {
                text: label; color: "#4a5568"; font.pixelSize: 11
                Layout.fillWidth: true; elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
            Text {
                text: buttonText; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.DemiBold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: buttonClicked() }
            }
        }
    }

    component ShortcutBtn: Rectangle {
        property string label: ""
        property color accent: "#06b6d4"
        signal clicked()

        Layout.fillWidth: true; height: 44; radius: 8
        color: scHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.08) : "#0a0e1a"
        border.color: "#141a2a"; border.width: 1

        Text {
            anchors.centerIn: parent
            text: label; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#7b8ba3"
        }

        MouseArea {
            id: scHover
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked()
        }
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}