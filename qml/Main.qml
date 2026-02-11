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

    Rectangle { anchors.fill: parent; color: "#0a0e1a" }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════ LEFT SIDEBAR ═══════════
        Rectangle {
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            color: "#06080f"

            Rectangle {
                anchors.right: parent.right
                width: 1; height: parent.height
                color: "#141a2a"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 16
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 0

                // Logo + Brand
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 20
                    spacing: 10

                    Rectangle {
                        width: 32; height: 32; radius: 8
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#06b6d4" }
                            GradientStop { position: 1.0; color: "#0ea5e9" }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "T"
                            font.pixelSize: 16; font.weight: Font.Black; color: "#fff"
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text { text: "Tweak"; color: "#f0f6ff"; font.pixelSize: 15; font.weight: Font.Bold }
                        Text { text: "v3.1"; color: "#2d3748"; font.pixelSize: 10 }
                    }
                }

                // Separator
                Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a"; Layout.bottomMargin: 12 }

                // Navigation
                Text { text: "NAVIGATION"; color: "#2d3748"; font.pixelSize: 9; font.weight: Font.Bold; Layout.leftMargin: 10; Layout.bottomMargin: 8 }

                NavItem { label: "Home";   tabIdx: 0 }
                NavItem { label: "Tweaks"; tabIdx: 1 }
                NavItem { label: "Games";  tabIdx: 2 }

                Item { Layout.fillHeight: true }

                // Separator
                Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a"; Layout.bottomMargin: 12 }

                // Status section
                Text { text: "STATUS"; color: "#2d3748"; font.pixelSize: 9; font.weight: Font.Bold; Layout.leftMargin: 10; Layout.bottomMargin: 8 }

                // Admin status
                Rectangle {
                    Layout.fillWidth: true
                    height: 36; radius: 8
                    color: appController.isAdmin ? "#0d2818" : "#1c1917"
                    border.color: appController.isAdmin ? "#166534" : "#854d0e"; border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: appController.isAdmin ? "#22c55e" : "#f59e0b"
                        }
                        Text {
                            Layout.fillWidth: true
                            text: appController.isAdmin ? "Administrator" : "Standard User"
                            color: appController.isAdmin ? "#22c55e" : "#f59e0b"
                            font.pixelSize: 11; font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                }

                // Active tweaks count
                Rectangle {
                    Layout.fillWidth: true; Layout.topMargin: 8
                    height: 36; radius: 8
                    color: "#0e1726"
                    border.color: "#164e63"; border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: "#22d3ee"
                        }
                        Text {
                            Layout.fillWidth: true
                            text: appController.appliedCount + " Active"
                            color: "#22d3ee"
                            font.pixelSize: 11; font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        // ═══════════ MAIN CONTENT AREA ═══════════
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

            // Page content
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

                GameBenchmarkPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    Cs2PathDialog { id: cs2PathDialog }

    // Restart Dialog
    Dialog {
        id: restartDialog
        anchors.centerIn: parent
        width: 400
        modal: true
        title: ""

        background: Rectangle {
            radius: 16; color: "#0f1423"
            border.color: "#1c2333"; border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 48; radius: 24
                color: "#0e2a3d"; border.color: "#06b6d4"; border.width: 1
                Text { anchors.centerIn: parent; text: "Restart"; font.pixelSize: 10; color: "#22d3ee"; font.weight: Font.Bold }
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

    // ═══════ Nav Item Component ═══════
    component NavItem: Rectangle {
        property string label: ""
        property int tabIdx: 0
        property bool active: root.currentPage === tabIdx

        Layout.fillWidth: true
        height: 38; radius: 8
        color: active ? "#0e1f3d" : navHover.containsMouse ? "#0c1527" : "transparent"
        border.color: active ? "#164e63" : "transparent"
        border.width: active ? 1 : 0
        Behavior on color { ColorAnimation { duration: 150 } }

        // Active indicator bar
        Rectangle {
            visible: active
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3; height: 20; radius: 2
            color: "#06b6d4"
        }

        Text {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: label
            color: active ? "#22d3ee" : navHover.containsMouse ? "#c5d0de" : "#7b8ba3"
            font.pixelSize: 13
            font.weight: active ? Font.Bold : Font.DemiBold
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: navHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentPage = tabIdx
        }
    }
}