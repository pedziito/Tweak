import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: root
    width: 1440
    height: 900
    minimumWidth: 1100
    minimumHeight: 700
    visible: true
    title: "Tweak"

    Material.theme: Material.Dark
    Material.accent: "#06b6d4"
    Material.primary: "#0a0e1a"
    Material.background: "#0a0e1a"

    font.family: "Segoe UI"
    font.pixelSize: 13
    color: "#0a0e1a"

    property int currentPage: 0

    Rectangle { anchors.fill: parent; color: "#0a0e1a" }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════ LEFT ICON SIDEBAR (Hone-style narrow) ═══════════
        Rectangle {
            Layout.preferredWidth: 62
            Layout.fillHeight: true
            color: "#06080f"

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: "#141a2a" }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 0

                // Logo
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.bottomMargin: 6

                    Rectangle {
                        anchors.centerIn: parent
                        width: 36; height: 36; radius: 10
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#06b6d4" }
                            GradientStop { position: 1.0; color: "#0ea5e9" }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "T"; font.pixelSize: 18; font.weight: Font.Black; color: "#fff"
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.leftMargin: 14; Layout.rightMargin: 14; height: 1; color: "#141a2a"; Layout.bottomMargin: 8 }

                // Nav icons — Canvas drawn
                SidebarIcon { iconType: "home";      tipText: "Home";   tabIdx: 0 }
                SidebarIcon { iconType: "lightning";  tipText: "Tweaks"; tabIdx: 1 }
                SidebarIcon { iconType: "gamepad";    tipText: "Games";  tabIdx: 2 }

                Item { Layout.fillHeight: true }

                // Admin indicator
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 34; height: 34; radius: 8
                    color: appController.isAdmin ? "#0d2818" : "#1c1917"
                    border.color: appController.isAdmin ? "#166534" : "#854d0e"; border.width: 1

                    Canvas {
                        anchors.centerIn: parent; width: 14; height: 14
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            if (appController.isAdmin) {
                                ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 2.2; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                ctx.beginPath(); ctx.moveTo(2, 8); ctx.lineTo(5, 11); ctx.lineTo(12, 3); ctx.stroke()
                            } else {
                                ctx.strokeStyle = "#f59e0b"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                ctx.beginPath(); ctx.moveTo(7, 1); ctx.lineTo(12, 3.5); ctx.lineTo(12, 7.5)
                                ctx.quadraticCurveTo(12, 13, 7, 14)
                                ctx.quadraticCurveTo(2, 13, 2, 7.5); ctx.lineTo(2, 3.5); ctx.closePath(); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(7, 5); ctx.lineTo(7, 8.5); ctx.stroke()
                                ctx.beginPath(); ctx.arc(7, 10.5, 0.7, 0, Math.PI * 2); ctx.fillStyle = "#f59e0b"; ctx.fill()
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }
                }

                // Tweak count
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 6
                    width: 34; height: 34; radius: 8
                    color: "#0e1726"; border.color: "#164e63"; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: appController.appliedCount
                        font.pixelSize: 12; font.weight: Font.Bold; color: "#22d3ee"
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4
                    text: "v3.3"; color: "#2d3748"; font.pixelSize: 9
                }
            }
        }

        // ═══════════ MAIN CONTENT ═══════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Top bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "#0a0e1a"

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141a2a" }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28; anchors.rightMargin: 28

                    Text {
                        text: {
                            switch(root.currentPage) {
                                case 0: return "Welcome to Tweak"
                                case 1: return "Your Optimizations"
                                case 2: return "Game Estimator"
                                default: return "Tweak"
                            }
                        }
                        color: "#f0f6ff"; font.pixelSize: 20; font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 10

                        Rectangle {
                            width: statusRow.width + 16; height: 30; radius: 8
                            color: "#0e1726"; border.color: "#164e63"; border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: statusRow
                                anchors.centerIn: parent; spacing: 6
                                Rectangle { width: 7; height: 7; radius: 4; color: "#22c55e"; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: appController.appliedCount + " Active"; color: "#22d3ee"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }
                        }

                        Rectangle {
                            visible: !appController.isAdmin
                            width: unlockLabel.width + 24; height: 30; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#f59e0b" }
                                GradientStop { position: 1.0; color: "#ef4444" }
                            }
                            Text { id: unlockLabel; anchors.centerIn: parent; text: "Run as Admin"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Bold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appController.requestAdmin() }
                        }
                    }
                }
            }

            // Pages
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage

                DashboardPage { Layout.fillWidth: true; Layout.fillHeight: true }
                TweaksPage { Layout.fillWidth: true; Layout.fillHeight: true; onRestartRequested: restartDialog.open() }
                GameBenchmarkPage { Layout.fillWidth: true; Layout.fillHeight: true }
            }
        }
    }

    Cs2PathDialog { id: cs2PathDialog }

    // Restart Dialog
    Dialog {
        id: restartDialog
        anchors.centerIn: parent; width: 400; modal: true; title: ""

        background: Rectangle { radius: 16; color: "#0f1423"; border.color: "#1c2333"; border.width: 1 }

        contentItem: ColumnLayout {
            spacing: 16

            Text { Layout.fillWidth: true; text: "Restart Required"; color: "#f0f6ff"; font.pixelSize: 20; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter }
            Text { Layout.fillWidth: true; text: "Tweaks applied. Restart your system for changes to take effect."; color: "#7b8ba3"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; lineHeight: 1.4 }

            RowLayout {
                Layout.fillWidth: true; spacing: 10; Layout.topMargin: 8

                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 10
                    color: "transparent"; border.color: "#1c2333"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Later"; color: "#7b8ba3"; font.pixelSize: 13; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: restartDialog.close() }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 10
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#06b6d4" }
                        GradientStop { position: 1.0; color: "#0ea5e9" }
                    }
                    Text { anchors.centerIn: parent; text: "Restart Now"; color: "#ffffff"; font.pixelSize: 13; font.weight: Font.Bold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.quit() }
                }
            }
        }
    }

    // ═══════ Sidebar Icon with Canvas-drawn icons ═══════
    component SidebarIcon: Item {
        property string iconType: "home"
        property string tipText: ""
        property int tabIdx: 0
        property bool active: root.currentPage === tabIdx

        Layout.fillWidth: true
        Layout.preferredHeight: 50

        Rectangle {
            anchors.centerIn: parent
            width: 42; height: 42; radius: 10
            color: active ? "#0e1f3d" : iconHover.containsMouse ? "#0c1527" : "transparent"
            border.color: active ? "#164e63" : "transparent"; border.width: active ? 1 : 0
            Behavior on color { ColorAnimation { duration: 150 } }

            // Active bar
            Rectangle {
                visible: active
                anchors.left: parent.left; anchors.leftMargin: -7
                anchors.verticalCenter: parent.verticalCenter
                width: 3; height: 20; radius: 2; color: "#06b6d4"
            }

            // Canvas icon
            Canvas {
                id: iconCanvas
                anchors.centerIn: parent
                width: 20; height: 20

                property color iconColor: active ? "#22d3ee" : iconHover.containsMouse ? "#c5d0de" : "#4a5568"
                Behavior on iconColor { ColorAnimation { duration: 150 } }
                onIconColorChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = iconColor
                    ctx.fillStyle = iconColor
                    ctx.lineWidth = 1.8
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    if (iconType === "home") {
                        // House icon
                        ctx.beginPath()
                        ctx.moveTo(10, 2)
                        ctx.lineTo(18, 9)
                        ctx.lineTo(16, 9)
                        ctx.lineTo(16, 17)
                        ctx.lineTo(12, 17)
                        ctx.lineTo(12, 12)
                        ctx.lineTo(8, 12)
                        ctx.lineTo(8, 17)
                        ctx.lineTo(4, 17)
                        ctx.lineTo(4, 9)
                        ctx.lineTo(2, 9)
                        ctx.closePath()
                        ctx.stroke()
                    }
                    else if (iconType === "lightning") {
                        // Lightning bolt
                        ctx.beginPath()
                        ctx.moveTo(11, 1)
                        ctx.lineTo(4, 11)
                        ctx.lineTo(9, 11)
                        ctx.lineTo(8, 19)
                        ctx.lineTo(16, 8)
                        ctx.lineTo(11, 8)
                        ctx.closePath()
                        ctx.stroke()
                    }
                    else if (iconType === "gamepad") {
                        // Gamepad
                        ctx.beginPath()
                        ctx.moveTo(2, 8)
                        ctx.quadraticCurveTo(2, 5, 6, 5)
                        ctx.lineTo(8, 5)
                        ctx.lineTo(8, 3)
                        ctx.lineTo(12, 3)
                        ctx.lineTo(12, 5)
                        ctx.lineTo(14, 5)
                        ctx.quadraticCurveTo(18, 5, 18, 8)
                        ctx.lineTo(18, 12)
                        ctx.quadraticCurveTo(18, 16, 15, 17)
                        ctx.lineTo(14, 14)
                        ctx.lineTo(6, 14)
                        ctx.lineTo(5, 17)
                        ctx.quadraticCurveTo(2, 16, 2, 12)
                        ctx.closePath()
                        ctx.stroke()
                        // D-pad
                        ctx.lineWidth = 1.5
                        ctx.beginPath(); ctx.moveTo(6, 8); ctx.lineTo(6, 12); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(4, 10); ctx.lineTo(8, 10); ctx.stroke()
                        // Buttons
                        ctx.beginPath(); ctx.arc(13, 9, 1.2, 0, Math.PI * 2); ctx.fill()
                        ctx.beginPath(); ctx.arc(15.5, 10.5, 1.2, 0, Math.PI * 2); ctx.fill()
                    }
                    else if (iconType === "gear") {
                        // Gear / settings
                        var cx = 10, cy = 10, or1 = 8, ir = 5.5
                        ctx.beginPath()
                        for (var i = 0; i < 8; i++) {
                            var a1 = (i * 45 - 12) * Math.PI / 180
                            var a2 = (i * 45 + 12) * Math.PI / 180
                            ctx.lineTo(cx + or1 * Math.cos(a1), cy + or1 * Math.sin(a1))
                            ctx.lineTo(cx + or1 * Math.cos(a2), cy + or1 * Math.sin(a2))
                            var a3 = (i * 45 + 22) * Math.PI / 180
                            var a4 = (i * 45 + 23) * Math.PI / 180
                            ctx.lineTo(cx + ir * Math.cos(a3), cy + ir * Math.sin(a3))
                            var a5 = ((i+1) * 45 - 23) * Math.PI / 180
                            ctx.lineTo(cx + ir * Math.cos(a5), cy + ir * Math.sin(a5))
                        }
                        ctx.closePath()
                        ctx.stroke()
                        ctx.beginPath(); ctx.arc(cx, cy, 3, 0, Math.PI * 2); ctx.stroke()
                    }
                }
                Component.onCompleted: requestPaint()
            }
        }

        // Tooltip
        Rectangle {
            id: tooltip
            visible: iconHover.containsMouse && !active
            x: parent.width + 4; anchors.verticalCenter: parent.verticalCenter
            width: tipLabel.width + 16; height: 28; radius: 6
            color: "#1a2040"; border.color: "#1c2333"; border.width: 1; z: 100
            Text { id: tipLabel; anchors.centerIn: parent; text: tipText; color: "#c5d0de"; font.pixelSize: 11; font.weight: Font.DemiBold }
        }

        MouseArea {
            id: iconHover
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentPage = tabIdx
        }
    }
}