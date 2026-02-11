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
    title: "Tweak  —  Performance Suite"

    Material.theme: Material.Dark
    Material.accent: "#06b6d4"
    Material.primary: "#0a0e1a"
    Material.background: "#0a0e1a"

    font.family: "Segoe UI"
    font.pixelSize: 13
    color: "#0a0e1a"

    property int currentPage: 0

    // ── Full-screen background ──
    Rectangle {
        anchors.fill: parent
        color: "#0a0e1a"
    }

    // ── Root layout: Sidebar + Content ──
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════ LEFT ICON SIDEBAR (Hone-style) ═══════════
        Rectangle {
            Layout.preferredWidth: 58
            Layout.fillHeight: true
            color: "#06080f"

            // Right border
            Rectangle {
                anchors.right: parent.right
                width: 1; height: parent.height
                color: "#141a2a"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 0

                // ── Logo ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    Layout.bottomMargin: 8

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34; height: 34; radius: 10
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#06b6d4" }
                            GradientStop { position: 1.0; color: "#0ea5e9" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "T"
                            font.pixelSize: 17
                            font.weight: Font.Black
                            color: "#ffffff"
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14; Layout.rightMargin: 14
                    height: 1; color: "#141a2a"
                    Layout.bottomMargin: 8
                }

                // ── Nav Icons ──
                SidebarIcon { iconText: "\u2302"; tipText: "Home";        tabIdx: 0 }
                SidebarIcon { iconText: "\u2699"; tipText: "Tweaks";      tabIdx: 1 }
                SidebarIcon { iconText: "\u25B2"; tipText: "Benchmark";   tabIdx: 2 }
                SidebarIcon { iconText: "\u265F"; tipText: "Games";       tabIdx: 3 }

                Item { Layout.fillHeight: true }

                // Admin indicator
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 36; height: 36; radius: 10
                    color: appController.isAdmin ? "#0d2818" : "#1c1917"
                    border.color: appController.isAdmin ? "#166534" : "#854d0e"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: appController.isAdmin ? "\u2713" : "\u26A0"
                        font.pixelSize: 14
                        color: appController.isAdmin ? "#22c55e" : "#f59e0b"
                    }
                }

                // Tweaks count
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    width: 36; height: 36; radius: 10
                    color: "#0e1726"
                    border.color: "#164e63"; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: appController.appliedCount
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: "#22d3ee"
                    }
                }

                // Version
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    text: "v3.0"
                    color: "#2d3748"
                    font.pixelSize: 9
                }
            }
        }

        // ═══════════ MAIN CONTENT AREA ═══════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ── Top title bar ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "#0a0e1a"

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: "#141a2a"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28

                    Text {
                        text: {
                            switch(root.currentPage) {
                                case 0: return "Welcome to Tweak"
                                case 1: return "Your Optimizations"
                                case 2: return "Performance Benchmark"
                                case 3: return "Game Estimator"
                                default: return "Tweak"
                            }
                        }
                        color: "#f0f6ff"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 10

                        Rectangle {
                            width: statusRow.width + 16; height: 30; radius: 8
                            color: "#0e1726"
                            border.color: "#164e63"; border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: statusRow
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle { width: 7; height: 7; radius: 4; color: "#22c55e"; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: appController.appliedCount + " Active"; color: "#22d3ee"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }
                        }

                        Rectangle {
                            visible: !appController.isAdmin
                            width: unlockRow.width + 18; height: 30; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#f59e0b" }
                                GradientStop { position: 1.0; color: "#ef4444" }
                            }

                            Row {
                                id: unlockRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "\u26A1"; font.pixelSize: 11; color: "#fff"; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Run as Admin"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Bold }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appController.requestAdmin()
                            }
                        }
                    }
                }
            }

            // ═══════════ PAGE CONTENT ═══════════
            StackLayout {
                id: pageStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage

                DashboardPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                TweaksPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onRestartRequested: restartDialog.open()
                }

                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                GameBenchmarkPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    Cs2PathDialog { id: cs2PathDialog }

    // ── Restart Dialog ──
    Dialog {
        id: restartDialog
        anchors.centerIn: parent
        width: 400
        modal: true
        title: ""

        background: Rectangle {
            radius: 16
            color: "#0f1423"
            border.color: "#1c2333"; border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 48; radius: 24
                color: "#0e2a3d"
                border.color: "#06b6d4"; border.width: 1
                Text { anchors.centerIn: parent; text: "\u21BB"; font.pixelSize: 20; color: "#22d3ee" }
            }

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

    // ═══════ Sidebar Icon Component ═══════
    component SidebarIcon: Item {
        property string iconText: ""
        property string tipText: ""
        property int tabIdx: 0
        property bool active: root.currentPage === tabIdx

        Layout.fillWidth: true
        Layout.preferredHeight: 48

        Rectangle {
            anchors.centerIn: parent
            width: 40; height: 40; radius: 10
            color: active ? "#0e1f3d" : iconHover.containsMouse ? "#0c1527" : "transparent"
            border.color: active ? "#164e63" : "transparent"
            border.width: active ? 1 : 0
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: iconText
                font.pixelSize: 17
                color: active ? "#22d3ee" : iconHover.containsMouse ? "#c5d0de" : "#4a5568"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Active indicator bar
            Rectangle {
                visible: active
                anchors.left: parent.left; anchors.leftMargin: -6
                anchors.verticalCenter: parent.verticalCenter
                width: 3; height: 20; radius: 2
                color: "#06b6d4"
            }
        }

        Rectangle {
            id: tooltip
            visible: iconHover.containsMouse && !active
            x: parent.width + 4
            anchors.verticalCenter: parent.verticalCenter
            width: tipLabel.width + 16; height: 28; radius: 6
            color: "#1a2040"; border.color: "#1c2333"; border.width: 1; z: 100
            Text { id: tipLabel; anchors.centerIn: parent; text: tipText; color: "#c5d0de"; font.pixelSize: 11; font.weight: Font.DemiBold }
        }

        MouseArea {
            id: iconHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentPage = tabIdx
        }
    }
}
