import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: root
    width: 1440; height: 900
    minimumWidth: 1100; minimumHeight: 700
    visible: true; title: "Tweak"

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
        anchors.fill: parent; spacing: 0

        // ═══════════ LEFT ICON SIDEBAR (Hone 1:1) ═══════════
        Rectangle {
            Layout.preferredWidth: 56; Layout.fillHeight: true
            color: "#06080f"
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: "#141a2a" }

            ColumnLayout {
                anchors.fill: parent; anchors.topMargin: 12; anchors.bottomMargin: 12; spacing: 0

                // Logo
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.centerIn: parent; width: 32; height: 32; radius: 8
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#f59e0b" }
                            GradientStop { position: 1.0; color: "#fbbf24" }
                        }
                        Text { anchors.centerIn: parent; text: "T"; font.pixelSize: 16; font.weight: Font.Black; color: "#fff" }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; height: 1; color: "#141a2a"; Layout.topMargin: 4; Layout.bottomMargin: 8 }

                // Nav icons — matching Hone sidebar order
                SidebarIcon { iconType: "home";      tipText: "Home";          tabIdx: 0 }
                SidebarIcon { iconType: "lightning";  tipText: "Optimizations"; tabIdx: 1 }
                SidebarIcon { iconType: "boost";      tipText: "Boost-Up";     tabIdx: -1 }
                SidebarIcon { iconType: "gamepad";    tipText: "Games";         tabIdx: 2 }
                SidebarIcon { iconType: "star";       tipText: "Favorites";     tabIdx: -1 }

                Item { Layout.fillHeight: true }

                SidebarIcon { iconType: "gear";       tipText: "Settings";      tabIdx: -1 }

                // Version
                Text {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8
                    text: "v4.0"; color: "#2d3748"; font.pixelSize: 8
                }
            }
        }

        // ═══════════ MAIN CONTENT ═══════════
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            // Top bar
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 52; color: "#0a0e1a"
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141a2a" }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 28; anchors.rightMargin: 28

                    Text {
                        text: {
                            switch(root.currentPage) {
                                case 0: return "Welcome to Tweak"
                                case 1: return "Optimizations"
                                case 2: return "Games"
                                default: return "Tweak"
                            }
                        }
                        color: "#f0f6ff"; font.pixelSize: 20; font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 10

                        // ? help button
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: "#0c1120"; border.color: "#141a2a"; border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "?"; color: "#7b8ba3"; font.pixelSize: 14; font.weight: Font.Bold }
                        }

                        // Run as Admin / Unlock button
                        Rectangle {
                            visible: !appController.isAdmin
                            width: unlockLabel.width + 32; height: 34; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#f59e0b" }
                                GradientStop { position: 1.0; color: "#ef4444" }
                            }
                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Canvas {
                                    width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = "#fff"; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // Shield/crown icon
                                        ctx.beginPath(); ctx.moveTo(2, 3); ctx.lineTo(4, 6); ctx.lineTo(7, 3); ctx.lineTo(10, 6); ctx.lineTo(12, 3)
                                        ctx.lineTo(12, 10); ctx.lineTo(7, 13); ctx.lineTo(2, 10); ctx.closePath(); ctx.stroke()
                                    }
                                    Component.onCompleted: requestPaint()
                                }
                                Text { id: unlockLabel; text: "Run as Admin"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appController.requestAdmin() }
                        }
                    }
                }
            }

            // Pages
            StackLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
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
        id: restartDialog; anchors.centerIn: parent; width: 400; modal: true; title: ""
        background: Rectangle { radius: 16; color: "#0f1423"; border.color: "#1c2333"; border.width: 1 }
        contentItem: ColumnLayout {
            spacing: 16
            Text { Layout.fillWidth: true; text: "Restart Required"; color: "#f0f6ff"; font.pixelSize: 20; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter }
            Text { Layout.fillWidth: true; text: "Tweaks applied. Restart your system for changes to take effect."; color: "#7b8ba3"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; lineHeight: 1.4 }
            RowLayout {
                Layout.fillWidth: true; spacing: 10; Layout.topMargin: 8
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 10; color: "transparent"; border.color: "#1c2333"; border.width: 1
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

    // ═══════ Sidebar Icon component ═══════
    component SidebarIcon: Item {
        property string iconType: "home"
        property string tipText: ""
        property int tabIdx: 0
        property bool active: tabIdx >= 0 && root.currentPage === tabIdx

        Layout.fillWidth: true; Layout.preferredHeight: 46

        // Active left bar
        Rectangle {
            visible: active
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: 3; height: 22; radius: 2; color: "#f59e0b"
        }

        Rectangle {
            anchors.centerIn: parent; width: 38; height: 38; radius: 10
            color: active ? "#1a1500" : iconHover.containsMouse ? "#0c1527" : "transparent"
            border.color: active ? "#3d2f00" : "transparent"; border.width: active ? 1 : 0
            Behavior on color { ColorAnimation { duration: 150 } }

            Canvas {
                id: iconCanvas; anchors.centerIn: parent; width: 20; height: 20
                property color iconColor: active ? "#f59e0b" : iconHover.containsMouse ? "#c5d0de" : "#4a5568"
                Behavior on iconColor { ColorAnimation { duration: 150 } }
                onIconColorChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = iconColor; ctx.fillStyle = iconColor
                    ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"

                    if (iconType === "home") {
                        ctx.beginPath()
                        ctx.moveTo(10, 2); ctx.lineTo(18, 9); ctx.lineTo(16, 9); ctx.lineTo(16, 17)
                        ctx.lineTo(12, 17); ctx.lineTo(12, 12); ctx.lineTo(8, 12); ctx.lineTo(8, 17)
                        ctx.lineTo(4, 17); ctx.lineTo(4, 9); ctx.lineTo(2, 9); ctx.closePath(); ctx.stroke()
                    } else if (iconType === "lightning") {
                        ctx.beginPath()
                        ctx.moveTo(11, 1); ctx.lineTo(4, 11); ctx.lineTo(9, 11)
                        ctx.lineTo(8, 19); ctx.lineTo(16, 8); ctx.lineTo(11, 8)
                        ctx.closePath(); ctx.stroke()
                    } else if (iconType === "boost") {
                        // Circular arrows (boost-up)
                        ctx.beginPath(); ctx.arc(10, 10, 7, -0.5, Math.PI * 1.2); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(14.5, 4); ctx.lineTo(14.5, 8); ctx.lineTo(10.5, 8); ctx.stroke()
                        ctx.beginPath(); ctx.arc(10, 10, 7, Math.PI - 0.5, Math.PI * 2.2); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(5.5, 16); ctx.lineTo(5.5, 12); ctx.lineTo(9.5, 12); ctx.stroke()
                    } else if (iconType === "gamepad") {
                        ctx.beginPath()
                        ctx.moveTo(2, 8); ctx.quadraticCurveTo(2, 5, 6, 5)
                        ctx.lineTo(8, 5); ctx.lineTo(8, 3); ctx.lineTo(12, 3); ctx.lineTo(12, 5); ctx.lineTo(14, 5)
                        ctx.quadraticCurveTo(18, 5, 18, 8); ctx.lineTo(18, 12)
                        ctx.quadraticCurveTo(18, 16, 15, 17); ctx.lineTo(14, 14); ctx.lineTo(6, 14); ctx.lineTo(5, 17)
                        ctx.quadraticCurveTo(2, 16, 2, 12); ctx.closePath(); ctx.stroke()
                        ctx.lineWidth = 1.5
                        ctx.beginPath(); ctx.moveTo(6, 8); ctx.lineTo(6, 12); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(4, 10); ctx.lineTo(8, 10); ctx.stroke()
                        ctx.beginPath(); ctx.arc(13, 9, 1.2, 0, Math.PI * 2); ctx.fill()
                        ctx.beginPath(); ctx.arc(15.5, 10.5, 1.2, 0, Math.PI * 2); ctx.fill()
                    } else if (iconType === "star") {
                        ctx.beginPath()
                        for (var i = 0; i < 5; i++) {
                            var oa = (i * 72 - 90) * Math.PI / 180
                            var ia = ((i * 72) + 36 - 90) * Math.PI / 180
                            ctx.lineTo(10 + 8 * Math.cos(oa), 10 + 8 * Math.sin(oa))
                            ctx.lineTo(10 + 3.5 * Math.cos(ia), 10 + 3.5 * Math.sin(ia))
                        }
                        ctx.closePath(); ctx.stroke()
                    } else if (iconType === "gear") {
                        var cx = 10, cy = 10
                        ctx.beginPath()
                        for (var j = 0; j < 8; j++) {
                            var a1 = (j * 45 - 12) * Math.PI / 180
                            var a2 = (j * 45 + 12) * Math.PI / 180
                            ctx.lineTo(cx + 8 * Math.cos(a1), cy + 8 * Math.sin(a1))
                            ctx.lineTo(cx + 8 * Math.cos(a2), cy + 8 * Math.sin(a2))
                            var a3 = (j * 45 + 22) * Math.PI / 180
                            var a5 = ((j+1) * 45 - 23) * Math.PI / 180
                            ctx.lineTo(cx + 5.5 * Math.cos(a3), cy + 5.5 * Math.sin(a3))
                            ctx.lineTo(cx + 5.5 * Math.cos(a5), cy + 5.5 * Math.sin(a5))
                        }
                        ctx.closePath(); ctx.stroke()
                        ctx.beginPath(); ctx.arc(cx, cy, 3, 0, Math.PI * 2); ctx.stroke()
                    }
                }
                Component.onCompleted: requestPaint()
            }
        }

        Rectangle {
            id: tooltip; visible: iconHover.containsMouse && !active
            x: parent.width + 4; anchors.verticalCenter: parent.verticalCenter
            width: tipLabel.width + 16; height: 28; radius: 6
            color: "#1a2040"; border.color: "#1c2333"; border.width: 1; z: 100
            Text { id: tipLabel; anchors.centerIn: parent; text: tipText; color: "#c5d0de"; font.pixelSize: 11; font.weight: Font.DemiBold }
        }

        MouseArea {
            id: iconHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { if (tabIdx >= 0) root.currentPage = tabIdx }
        }
    }
}
