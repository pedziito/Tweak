import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Flickable {
    id: dashRoot
    contentWidth: width; contentHeight: outerCol.implicitHeight + 56
    clip: true; boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    ColumnLayout {
        id: outerCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 28; spacing: 20

        // ═══════ TOP ROW: 3 stat cards + CPU gauge ═══════
        RowLayout {
            Layout.fillWidth: true; spacing: 14

            // Stat card 1 — Optimizations Active
            DashStatCard {
                Layout.fillWidth: true
                iconType: "rocket"; iconColor: "#06b6d4"
                value: appController.appliedCount
                label: "Optimizations Active"
                buttonText: "View Optimizations"
                onButtonClicked: root.currentPage = 1
            }

            // Stat card 2 — Recommended
            DashStatCard {
                Layout.fillWidth: true
                iconType: "refresh"; iconColor: "#f59e0b"
                value: appController.recommendedCount
                label: "Recommended Available"
                buttonText: "View Recommended"
                onButtonClicked: root.currentPage = 1
            }

            // Stat card 3 — Game Settings
            DashStatCard {
                Layout.fillWidth: true
                iconType: "gamepad"; iconColor: "#8b5cf6"
                value: 0
                label: "Game Settings Active"
                buttonText: "View Games"
                onButtonClicked: root.currentPage = 2
            }

            // CPU Usage card
            Rectangle {
                Layout.fillWidth: true; Layout.preferredWidth: 340; Layout.minimumWidth: 280
                height: 130; radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

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
                                    ctx.beginPath(); ctx.roundedRect(1, 1, 14, 10, 2, 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(5, 13); ctx.lineTo(11, 13); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(8, 11); ctx.lineTo(8, 13); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }
                            Text { text: "CPU USAGE"; color: "#7b8ba3"; font.pixelSize: 10; font.weight: Font.Bold }
                        }

                        // Current Load text
                        ColumnLayout {
                            spacing: 0
                            Text { text: "Current Load"; color: "#5a6a7c"; font.pixelSize: 11 }
                            Text {
                                text: Math.round(appController.systemMonitor.cpuUsage) + "%"
                                color: "#f0f6ff"; font.pixelSize: 26; font.weight: Font.Bold
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Mini graph
                        Canvas {
                            id: cpuMiniGraph; Layout.fillWidth: true; Layout.preferredHeight: 50

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
                                var ctx = getContext("2d"); ctx.reset()
                                var w = width, h = height; if (history.length < 2) return
                                ctx.strokeStyle = "#141a2a"; ctx.lineWidth = 1
                                for (var g = 0; g < 3; g++) { var gy = h * g / 3; ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke() }
                                var grad = ctx.createLinearGradient(0, 0, 0, h)
                                grad.addColorStop(0, "rgba(34,197,94,0.15)"); grad.addColorStop(1, "rgba(34,197,94,0.0)")
                                ctx.fillStyle = grad; ctx.beginPath(); ctx.moveTo(0, h)
                                for (var i = 0; i < history.length; i++) ctx.lineTo(i * w / (maxPoints - 1), h - (history[i] / 100) * h)
                                ctx.lineTo((history.length - 1) * w / (maxPoints - 1), h); ctx.closePath(); ctx.fill()
                                ctx.beginPath(); ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 2; ctx.lineJoin = "round"
                                for (var j = 0; j < history.length; j++) {
                                    var lx = j * w / (maxPoints - 1), ly = h - (history[j] / 100) * h
                                    if (j === 0) ctx.moveTo(lx, ly); else ctx.lineTo(lx, ly)
                                }
                                ctx.stroke()
                                if (history.length > 0) {
                                    var ex = (history.length - 1) * w / (maxPoints - 1), ey = h - (history[history.length - 1] / 100) * h
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

        // ═══════ MIDDLE: Your Optimizations (left) + GPU/RAM + Shortcuts (right) ═══════
        RowLayout {
            Layout.fillWidth: true; spacing: 20

            // LEFT: Your Optimizations
            ColumnLayout {
                Layout.fillWidth: true; Layout.minimumWidth: 300; spacing: 0

                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 12
                    Row {
                        spacing: 8
                        Rectangle { width: 8; height: 8; radius: 4; color: "#4a5568"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Your Optimizations"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "Create New Preset"; color: "#5a6a7c"; font.pixelSize: 11; font.weight: Font.DemiBold }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 320
                    radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                    // Empty state (shown when no tweaks applied, like Hone)
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 12
                        visible: appController.appliedCount === 0

                        Canvas {
                            Layout.alignment: Qt.AlignHCenter; width: 48; height: 48
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.strokeStyle = "#3d4a5c"; ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                // Terminal/code icon
                                ctx.beginPath(); ctx.roundedRect(4, 8, 40, 32, 4, 4); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(14, 18); ctx.lineTo(10, 24); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(14, 30); ctx.lineTo(10, 24); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(22, 30); ctx.lineTo(30, 30); ctx.stroke()
                            }
                            Component.onCompleted: requestPaint()
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "It's empty here..."
                            color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "You could use some optimizations, check\nout the recommended section or go to\noptimizations page to boost performance."
                            color: "#5a6a7c"; font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter; lineHeight: 1.4
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8
                            width: goLabel.width + 40; height: 38; radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#06b6d4" }
                                GradientStop { position: 1.0; color: "#0ea5e9" }
                            }
                            Text { id: goLabel; anchors.centerIn: parent; text: "Go To Optimizations"; color: "#fff"; font.pixelSize: 12; font.weight: Font.Bold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentPage = 1 }
                        }
                    }

                    // Applied tweaks list (when tweaks are applied)
                    Flickable {
                        anchors.fill: parent; anchors.margins: 16
                        contentHeight: appliedCol.implicitHeight; clip: true
                        visible: appController.appliedCount > 0
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle { implicitWidth: 3; radius: 2; color: "#06b6d4"; opacity: 0.4 }
                            background: Rectangle { color: "transparent" }
                        }

                        ColumnLayout {
                            id: appliedCol
                            width: parent.width; spacing: 0

                            Repeater {
                                model: appController.tweakModel.rowCount()
                                delegate: Rectangle {
                                    property bool isApplied: appController.tweakModel.data(appController.tweakModel.index(index, 0), 262) || false
                                    Layout.fillWidth: true; implicitHeight: isApplied ? 44 : 0
                                    visible: isApplied
                                    color: aOptHover.containsMouse ? "#111827" : "transparent"

                                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141a2a"; visible: isApplied }

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 10
                                        visible: isApplied
                                        Text {
                                            text: appController.tweakModel.data(appController.tweakModel.index(index, 0), 258) || ""
                                            color: "#c5d0de"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Switch {
                                            checked: true
                                            indicator: Rectangle {
                                                implicitWidth: 38; implicitHeight: 20; radius: 10
                                                color: "#0d3a4a"; border.color: "#06b6d4"; border.width: 1
                                                Rectangle {
                                                    x: parent.width - width - 3; anchors.verticalCenter: parent.verticalCenter
                                                    width: 14; height: 14; radius: 7; color: "#22d3ee"
                                                }
                                            }
                                            onToggled: appController.toggleTweak(index)
                                        }
                                    }

                                    MouseArea {
                                        id: aOptHover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
                                        visible: isApplied
                                        onClicked: function(mouse) { mouse.accepted = false }
                                        onPressed: function(mouse) { mouse.accepted = false }
                                        onReleased: function(mouse) { mouse.accepted = false }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // RIGHT: GPU/RAM gauges + Shortcuts
            ColumnLayout {
                Layout.preferredWidth: 360; Layout.minimumWidth: 260; Layout.maximumWidth: 420; spacing: 14

                RowLayout {
                    Layout.fillWidth: true; spacing: 14

                    // GPU Usage
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: gpuGaugeCol.implicitHeight + 28
                        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                        ColumnLayout {
                            id: gpuGaugeCol; anchors.centerIn: parent; spacing: 8
                            Row {
                                Layout.alignment: Qt.AlignHCenter; spacing: 6
                                Canvas {
                                    width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = "#06b6d4"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
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
                                Layout.alignment: Qt.AlignHCenter; width: 80; height: 80
                                value: appController.systemMonitor.storageUsage
                                startColor: "#06b6d4"; endColor: "#22d3ee"; lineWidth: 7; label: ""
                            }
                        }
                    }

                    // RAM Usage
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: ramGaugeCol.implicitHeight + 28
                        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                        ColumnLayout {
                            id: ramGaugeCol; anchors.centerIn: parent; spacing: 8
                            Row {
                                Layout.alignment: Qt.AlignHCenter; spacing: 6
                                Canvas {
                                    width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = "#f59e0b"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
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
                                Layout.alignment: Qt.AlignHCenter; width: 80; height: 80
                                value: appController.systemMonitor.ramUsage
                                startColor: "#f59e0b"; endColor: "#fbbf24"; lineWidth: 7; label: ""
                            }
                        }
                    }
                }

                // Shortcuts (Hone-style)
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: scCol.implicitHeight + 28
                    radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                    ColumnLayout {
                        id: scCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 14; spacing: 10

                        Row {
                            spacing: 6
                            Canvas {
                                width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = "#5a6a7c"; ctx.lineWidth = 1.4; ctx.lineCap = "round"
                                    ctx.beginPath(); ctx.arc(7, 7, 5.5, 0, Math.PI * 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(7, 4); ctx.lineTo(7, 7.5); ctx.lineTo(10, 9); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }
                            Text { text: "Shortcuts"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.Bold }
                        }

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

        // ═══════ BOTTOM: Hardware + Score ═══════
        RowLayout {
            Layout.fillWidth: true; spacing: 14

            Rectangle {
                Layout.fillWidth: true; implicitHeight: hwCol.implicitHeight + 36
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
                Layout.preferredWidth: 280; implicitHeight: hwCol.implicitHeight + 36; Layout.minimumHeight: implicitHeight
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

        Layout.fillWidth: true; height: 130; radius: 14
        color: "#0c1120"; border.color: "#141a2a"; border.width: 1; clip: true

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 6

            RowLayout {
                spacing: 8
                Canvas {
                    width: 22; height: 22
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.strokeStyle = iconColor; ctx.fillStyle = iconColor
                        ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"
                        if (iconType === "rocket") {
                            ctx.beginPath(); ctx.moveTo(11, 2); ctx.quadraticCurveTo(18, 4, 18, 11)
                            ctx.lineTo(14, 16); ctx.lineTo(8, 16); ctx.lineTo(4, 11); ctx.quadraticCurveTo(4, 4, 11, 2)
                            ctx.closePath(); ctx.stroke()
                            ctx.beginPath(); ctx.arc(11, 9, 2.5, 0, Math.PI * 2); ctx.stroke()
                        } else if (iconType === "refresh") {
                            ctx.beginPath(); ctx.arc(11, 11, 7, -0.5, Math.PI * 1.5); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(14, 4); ctx.lineTo(17, 6); ctx.lineTo(14, 8); ctx.stroke()
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
                // Arrow circle badge
                Canvas {
                    width: 20; height: 20; visible: value > 0
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.strokeStyle = iconColor; ctx.lineWidth = 1.4; ctx.lineCap = "round"
                        ctx.beginPath(); ctx.arc(10, 10, 8, 0, Math.PI * 2); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(7, 7); ctx.lineTo(10, 13); ctx.lineTo(13, 7); ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                }
            }

            Text { text: value; color: "#f0f6ff"; font.pixelSize: 28; font.weight: Font.Bold }
            Text { text: label; color: "#5a6a7c"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            Item { Layout.fillHeight: true }
            Text {
                text: buttonText; color: "#5a6a7c"; font.pixelSize: 11; font.weight: Font.DemiBold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: buttonClicked() }
            }
        }
    }

    component ShortcutBtn: Rectangle {
        property string label: ""; property string iconType: ""; property color accent: "#06b6d4"
        signal clicked()
        Layout.fillWidth: true; height: 72; radius: 10
        color: scHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.08) : "#0a0e1a"
        border.color: "#141a2a"; border.width: 1
        ColumnLayout {
            anchors.centerIn: parent; spacing: 6
            Canvas {
                Layout.alignment: Qt.AlignHCenter; width: 22; height: 22
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset(); ctx.strokeStyle = accent; ctx.fillStyle = accent
                    ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"
                    if (iconType === "lightning") {
                        ctx.beginPath(); ctx.moveTo(12, 1); ctx.lineTo(5, 12); ctx.lineTo(10, 12)
                        ctx.lineTo(9, 21); ctx.lineTo(17, 9); ctx.lineTo(12, 9); ctx.closePath(); ctx.stroke()
                    } else if (iconType === "restore") {
                        ctx.beginPath(); ctx.arc(11, 11, 8, -0.5, Math.PI * 1.7); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(4, 2); ctx.lineTo(4, 8); ctx.lineTo(10, 8); ctx.stroke()
                    } else if (iconType === "check") {
                        ctx.lineWidth = 2.5; ctx.beginPath(); ctx.moveTo(3, 12); ctx.lineTo(8, 17); ctx.lineTo(19, 5); ctx.stroke()
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
