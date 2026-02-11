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

        // ═══════ TOP: Stats (3 cards) + CPU gauge card ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // 3 stat cards on the left
            DashStatCard {
                Layout.fillWidth: true
                iconType: "rocket"
                iconColor: "#06b6d4"
                value: appController.appliedCount
                label: "Optimizations Active"
                buttonText: "View Optimizations"
                onButtonClicked: root.currentPage = 1
            }
            DashStatCard {
                Layout.fillWidth: true
                iconType: "star"
                iconColor: "#f59e0b"
                value: appController.recommendedCount
                label: "Recommended Available"
                buttonText: "View Recommended"
                onButtonClicked: root.currentPage = 1
            }
            DashStatCard {
                Layout.fillWidth: true
                iconType: "gamepad"
                iconColor: "#8b5cf6"
                value: appController.tweakModel.rowCount()
                label: "Total Tweaks"
                buttonText: "View All"
                onButtonClicked: root.currentPage = 1
            }

            // CPU Usage card (right side of top row, like Hone)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 320
                Layout.minimumWidth: 250
                height: 130
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 4

                        Row {
                            spacing: 6
                            Canvas {
                                width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                    // Monitor icon
                                    ctx.beginPath(); ctx.roundedRect(1, 1, 14, 10, 2, 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(5, 13); ctx.lineTo(11, 13); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(8, 11); ctx.lineTo(8, 13); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }
                            Text { text: "CPU USAGE"; color: "#7b8ba3"; font.pixelSize: 10; font.weight: Font.Bold }
                        }

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
                                grad.addColorStop(0, "rgba(34,197,94,0.15)")
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
                        width: 80; height: 80; Layout.alignment: Qt.AlignVCenter
                        value: appController.systemMonitor.cpuUsage
                        startColor: "#22c55e"; endColor: "#4ade80"; lineWidth: 7; label: ""
                    }
                }
            }
        }

        // ═══════ MIDDLE: Left optimizations + Right gauges/shortcuts ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // LEFT: Optimizations
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 300
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 12

                    Row {
                        spacing: 8
                        Rectangle { width: 8; height: 8; radius: 4; color: "#06b6d4"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Your Optimizations"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: mLabel.width + 20; height: 30; radius: 8
                        color: "#0f1423"; border.color: "#1c2333"; border.width: 1
                        Text { id: mLabel; anchors.centerIn: parent; text: "Manage Presets"; color: "#7b8ba3"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentPage = 1 }
                    }
                }

                Repeater {
                    model: Math.min(8, appController.tweakModel.rowCount())

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: optRowLayout.implicitHeight + 16
                        color: optHover.containsMouse ? "#0e1424" : "transparent"

                        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#141a2a" }

                        RowLayout {
                            id: optRowLayout
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 4; anchors.rightMargin: 12
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2

                                Text {
                                    text: appController.tweakModel.data(appController.tweakModel.index(index, 0), 258) || ""
                                    color: "#e0f7ff"; font.pixelSize: 13; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: {
                                        var desc = appController.tweakModel.data(appController.tweakModel.index(index, 0), 259) || ""
                                        return desc.length > 55 ? desc.substring(0, 52) + "..." : desc
                                    }
                                    color: "#4a5568"; font.pixelSize: 11
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                visible: {
                                    var s = appController.tweakModel.data(appController.tweakModel.index(index, 0), 267) || "stable"
                                    return s !== "stable"
                                }
                                width: sBText.width + 12; height: 20; radius: 4
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
                                    id: sBText
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

                            Switch {
                                id: dashSwitch
                                checked: appController.tweakModel.data(appController.tweakModel.index(index, 0), 262) || false
                                indicator: Rectangle {
                                    implicitWidth: 42; implicitHeight: 22
                                    x: dashSwitch.leftPadding; y: parent.height / 2 - height / 2; radius: 11
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

                Rectangle {
                    Layout.fillWidth: true; Layout.topMargin: 8; height: 36; radius: 8
                    color: vaHover.containsMouse ? "#0e1424" : "transparent"
                    Text { anchors.centerIn: parent; text: "View all " + appController.tweakModel.rowCount() + " optimizations"; color: "#06b6d4"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    MouseArea { id: vaHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentPage = 1 }
                }
            }

            // RIGHT: GPU/RAM gauges + shortcuts
            ColumnLayout {
                Layout.preferredWidth: 360
                Layout.minimumWidth: 260
                Layout.maximumWidth: 420
                spacing: 14

                // GPU + RAM side-by-side
                RowLayout {
                    Layout.fillWidth: true; spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: diskGaugeCol.implicitHeight + 28
                        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                        ColumnLayout {
                            id: diskGaugeCol
                            anchors.centerIn: parent; spacing: 8
                            Row {
                                Layout.alignment: Qt.AlignHCenter; spacing: 6
                                Canvas {
                                    width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = "#06b6d4"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // GPU chip icon
                                        ctx.beginPath(); ctx.roundedRect(3, 3, 10, 10, 1.5, 1.5); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(5, 3); ctx.lineTo(5, 1); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(8, 3); ctx.lineTo(8, 1); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(11, 3); ctx.lineTo(11, 1); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(5, 13); ctx.lineTo(5, 15); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(8, 13); ctx.lineTo(8, 15); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(11, 13); ctx.lineTo(11, 15); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(3, 6); ctx.lineTo(1, 6); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(3, 10); ctx.lineTo(1, 10); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(13, 6); ctx.lineTo(15, 6); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(13, 10); ctx.lineTo(15, 10); ctx.stroke()
                                    }
                                    Component.onCompleted: requestPaint()
                                }
                                Text { text: "GPU USAGE"; color: "#7b8ba3"; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                            CircularGauge {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80; height: 80
                                value: appController.systemMonitor.storageUsage
                                startColor: "#06b6d4"; endColor: "#22d3ee"; lineWidth: 7; label: ""
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: ramGaugeCol.implicitHeight + 28
                        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                        ColumnLayout {
                            id: ramGaugeCol
                            anchors.centerIn: parent; spacing: 8
                            Row {
                                Layout.alignment: Qt.AlignHCenter; spacing: 6
                                Canvas {
                                    width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = "#f59e0b"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // RAM stick icon
                                        ctx.beginPath(); ctx.roundedRect(2, 3, 12, 10, 1.5, 1.5); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(5, 3); ctx.lineTo(5, 6); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(8, 3); ctx.lineTo(8, 6); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(11, 3); ctx.lineTo(11, 6); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(6, 13); ctx.lineTo(6, 15); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(10, 13); ctx.lineTo(10, 15); ctx.stroke()
                                    }
                                    Component.onCompleted: requestPaint()
                                }
                                Text { text: "RAM USAGE"; color: "#7b8ba3"; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                            CircularGauge {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80; height: 80
                                value: appController.systemMonitor.ramUsage
                                startColor: "#f59e0b"; endColor: "#fbbf24"; lineWidth: 7; label: ""
                            }
                        }
                    }
                }

                // Shortcuts (Hone-style grid)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: scCol.implicitHeight + 28
                    radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                    ColumnLayout {
                        id: scCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 14; spacing: 10

                        Text { text: "Shortcuts"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }

                        GridLayout {
                            Layout.fillWidth: true; columns: 4; rowSpacing: 8; columnSpacing: 8

                            ShortcutBtn { label: "Apply All";  iconType: "lightning"; accent: "#06b6d4"; onClicked: appController.applyAllGaming() }
                            ShortcutBtn { label: "Restore";    iconType: "restore";   accent: "#f43f5e"; onClicked: appController.restoreAll() }
                            ShortcutBtn { label: "Verify";     iconType: "check";     accent: "#22c55e"; onClicked: appController.verifyAllTweaks() }
                            ShortcutBtn { label: "Games";      iconType: "gamepad";   accent: "#f59e0b"; onClicked: root.currentPage = 2 }
                        }
                    }
                }
            }
        }

        // ═══════ BOTTOM: Hardware + Score + Game Profiles ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

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

            Rectangle {
                Layout.preferredWidth: 240
                implicitHeight: hwCol.implicitHeight + 36; Layout.minimumHeight: implicitHeight
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
                        Layout.fillWidth: true; spacing: 16
                        CircularGauge {
                            width: 60; height: 60; Layout.alignment: Qt.AlignVCenter
                            value: appController.hwScorer ? appController.hwScorer.gamingScore : 0
                            startColor: "#06b6d4"; endColor: "#22d3ee"; lineWidth: 5; label: ""
                        }
                        ColumnLayout {
                            spacing: 4
                            Text { text: "Gaming"; color: "#7b8ba3"; font.pixelSize: 11 }
                            Text { text: appController.hwScorer ? appController.hwScorer.tier : "N/A"; color: "#22d3ee"; font.pixelSize: 16; font.weight: Font.Bold }
                            Text {
                                visible: appController.hwScorer && appController.hwScorer.bottleneck !== ""
                                text: appController.hwScorer ? appController.hwScorer.bottleneck : ""; color: "#fbbf24"; font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                implicitHeight: gpCol.implicitHeight + 36; Layout.minimumHeight: implicitHeight
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    id: gpCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 18; spacing: 8
                    Text { text: "Game Profiles"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }
                    // imagePath can be set to a local file like "file:///C:/images/cs2.png"
                    GameProfileCard { Layout.fillWidth: true; gameName: "CS2"; gameDesc: "Max FPS"; gradStart: "#f59e0b"; gradEnd: "#ef4444"; onOptimize: optimized = !optimized }
                    GameProfileCard { Layout.fillWidth: true; gameName: "Fortnite"; gameDesc: "Balanced"; gradStart: "#06b6d4"; gradEnd: "#0ea5e9"; onOptimize: optimized = !optimized }
                    GameProfileCard { Layout.fillWidth: true; gameName: "Valorant"; gameDesc: "Low latency"; gradStart: "#ef4444"; gradEnd: "#dc2626"; onOptimize: optimized = !optimized }
                    GameProfileCard { Layout.fillWidth: true; gameName: "Apex"; gameDesc: "Smooth FPS"; gradStart: "#dc2626"; gradEnd: "#f59e0b"; onOptimize: optimized = !optimized }
                }
            }
        }

        Item { height: 16 }
    }

    // ── Components ──
    component HwLabel: Text { color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold; Layout.preferredWidth: 50 }
    component HwValue: Text { color: "#c5d0de"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }

    component DashStatCard: Rectangle {
        property string iconType: "rocket"
        property color iconColor: "#06b6d4"
        property int value: 0
        property string label: ""
        property string buttonText: ""
        signal buttonClicked()

        Layout.fillWidth: true
        height: 130; radius: 14
        color: "#0c1120"; border.color: "#141a2a"; border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 6

            RowLayout {
                spacing: 8

                // Canvas icon for stat card
                Canvas {
                    width: 22; height: 22
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = iconColor; ctx.fillStyle = iconColor
                        ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"

                        if (iconType === "rocket") {
                            ctx.beginPath()
                            ctx.moveTo(11, 2)
                            ctx.quadraticCurveTo(18, 4, 18, 11)
                            ctx.lineTo(14, 16)
                            ctx.lineTo(8, 16)
                            ctx.lineTo(4, 11)
                            ctx.quadraticCurveTo(4, 4, 11, 2)
                            ctx.closePath(); ctx.stroke()
                            ctx.beginPath(); ctx.arc(11, 9, 2.5, 0, Math.PI * 2); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(8, 16); ctx.lineTo(6, 20); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(14, 16); ctx.lineTo(16, 20); ctx.stroke()
                        } else if (iconType === "star") {
                            ctx.beginPath()
                            for (var i = 0; i < 5; i++) {
                                var outerAngle = (i * 72 - 90) * Math.PI / 180
                                var innerAngle = ((i * 72) + 36 - 90) * Math.PI / 180
                                ctx.lineTo(11 + 9 * Math.cos(outerAngle), 11 + 9 * Math.sin(outerAngle))
                                ctx.lineTo(11 + 4 * Math.cos(innerAngle), 11 + 4 * Math.sin(innerAngle))
                            }
                            ctx.closePath(); ctx.stroke()
                        } else if (iconType === "gamepad") {
                            ctx.beginPath()
                            ctx.moveTo(3, 9)
                            ctx.quadraticCurveTo(3, 5, 7, 5)
                            ctx.lineTo(9, 5); ctx.lineTo(9, 3.5); ctx.lineTo(13, 3.5); ctx.lineTo(13, 5)
                            ctx.lineTo(15, 5)
                            ctx.quadraticCurveTo(19, 5, 19, 9)
                            ctx.lineTo(19, 13)
                            ctx.quadraticCurveTo(19, 17, 16, 18)
                            ctx.lineTo(15, 15); ctx.lineTo(7, 15); ctx.lineTo(6, 18)
                            ctx.quadraticCurveTo(3, 17, 3, 13)
                            ctx.closePath(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(7, 8.5); ctx.lineTo(7, 12.5); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(5, 10.5); ctx.lineTo(9, 10.5); ctx.stroke()
                            ctx.beginPath(); ctx.arc(14, 10, 1, 0, Math.PI * 2); ctx.fill()
                            ctx.beginPath(); ctx.arc(16.5, 11.5, 1, 0, Math.PI * 2); ctx.fill()
                        }
                    }
                    Component.onCompleted: requestPaint()
                }

                Rectangle {
                    visible: value > 0
                    width: 20; height: 20; radius: 10
                    color: Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0.15)
                    border.color: Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0.3); border.width: 1
                    Canvas {
                        anchors.centerIn: parent; width: 10; height: 10
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset(); ctx.strokeStyle = iconColor; ctx.lineWidth = 2; ctx.lineCap = "round"
                            ctx.beginPath(); ctx.moveTo(1, 5.5); ctx.lineTo(4, 8.5); ctx.lineTo(9, 2); ctx.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }
                }
            }

            Text { text: value; color: "#f0f6ff"; font.pixelSize: 28; font.weight: Font.Bold }
            Text { text: label; color: "#4a5568"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            Item { Layout.fillHeight: true }
            Text {
                text: buttonText; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.DemiBold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: buttonClicked() }
            }
        }
    }

    component ShortcutBtn: Rectangle {
        property string label: ""
        property string iconType: ""
        property color accent: "#06b6d4"
        signal clicked()

        Layout.fillWidth: true; height: 72; radius: 10
        color: scHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.08) : "#0a0e1a"
        border.color: "#141a2a"; border.width: 1

        ColumnLayout {
            anchors.centerIn: parent; spacing: 6

            Canvas {
                Layout.alignment: Qt.AlignHCenter; width: 22; height: 22
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset(); ctx.strokeStyle = accent; ctx.fillStyle = accent
                    ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"

                    if (iconType === "lightning") {
                        ctx.beginPath(); ctx.moveTo(12, 1); ctx.lineTo(5, 12); ctx.lineTo(10, 12)
                        ctx.lineTo(9, 21); ctx.lineTo(17, 9); ctx.lineTo(12, 9); ctx.closePath(); ctx.stroke()
                    } else if (iconType === "restore") {
                        ctx.beginPath(); ctx.arc(11, 11, 8, -0.5, Math.PI * 1.7); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(4, 2); ctx.lineTo(4, 8); ctx.lineTo(10, 8); ctx.stroke()
                    } else if (iconType === "check") {
                        ctx.lineWidth = 2.5
                        ctx.beginPath(); ctx.moveTo(3, 12); ctx.lineTo(8, 17); ctx.lineTo(19, 5); ctx.stroke()
                    } else if (iconType === "gamepad") {
                        ctx.beginPath()
                        ctx.moveTo(3, 9); ctx.quadraticCurveTo(3, 5, 7, 5)
                        ctx.lineTo(9, 5); ctx.lineTo(9, 3.5); ctx.lineTo(13, 3.5); ctx.lineTo(13, 5); ctx.lineTo(15, 5)
                        ctx.quadraticCurveTo(19, 5, 19, 9); ctx.lineTo(19, 13)
                        ctx.quadraticCurveTo(19, 17, 16, 18); ctx.lineTo(15, 15); ctx.lineTo(7, 15); ctx.lineTo(6, 18)
                        ctx.quadraticCurveTo(3, 17, 3, 13); ctx.closePath(); ctx.stroke()
                    }
                }
                Component.onCompleted: requestPaint()
            }
            Text { Layout.alignment: Qt.AlignHCenter; text: label; font.pixelSize: 10; font.weight: Font.DemiBold; color: "#7b8ba3" }
        }

        MouseArea { id: scHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}