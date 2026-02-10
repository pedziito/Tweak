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
    Material.primary: "#0b0f19"
    Material.background: "#0b0f19"

    font.family: "Segoe UI"
    font.pixelSize: 13
    color: "#0b0f19"

    property int currentPage: 0

    // ── Full-screen background ──
    Rectangle {
        anchors.fill: parent
        color: "#0b0f19"
    }

    // Ambient glow: top-left cyan
    Rectangle {
        width: 600; height: 600
        x: -150; y: -150
        radius: 300
        opacity: 0.035
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#06b6d4" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Ambient glow: bottom-right amber
    Rectangle {
        width: 500; height: 500
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -120
        anchors.bottomMargin: -120
        radius: 250
        opacity: 0.025
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f59e0b" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ── Root layout: TopBar + Content ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════ TOP NAV BAR ═══════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#0f1423"

            // Bottom border
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: "#1c2333"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 0

                // ── Logo ──
                Row {
                    spacing: 10
                    Layout.rightMargin: 36

                    Rectangle {
                        width: 32; height: 32; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#06b6d4" }
                            GradientStop { position: 1.0; color: "#0ea5e9" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "T"
                            font.pixelSize: 16
                            font.weight: Font.Black
                            color: "#ffffff"
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Tweak"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#f0f6ff"
                        font.letterSpacing: 0.5
                    }
                }

                // ── Nav Tabs ──
                Row {
                    spacing: 4

                    NavTab { label: "Dashboard";      icon: "\u25C8"; tabIndex: 0 }
                    NavTab { label: "Tweaks";         icon: "\u2699"; tabIndex: 1 }
                    NavTab { label: "Benchmark";      icon: "\u25B2"; tabIndex: 2 }
                    NavTab { label: "Game Estimator"; icon: "\u265F"; tabIndex: 3 }
                }

                Item { Layout.fillWidth: true }

                // ── Right side: status indicators ──
                Row {
                    spacing: 12
                    anchors.verticalCenter: parent.verticalCenter

                    // Admin badge
                    Rectangle {
                        visible: appController.isAdmin
                        width: adminRow.width + 16; height: 28; radius: 6
                        color: "#0d2818"
                        border.color: "#166534"; border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: adminRow
                            anchors.centerIn: parent
                            spacing: 5
                            Rectangle { width: 6; height: 6; radius: 3; color: "#22c55e"; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Admin"; color: "#22c55e"; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }

                    // Not admin badge
                    Rectangle {
                        visible: !appController.isAdmin
                        width: noAdminRow.width + 16; height: 28; radius: 6
                        color: "#1c1917"
                        border.color: "#854d0e"; border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: noAdminRow
                            anchors.centerIn: parent
                            spacing: 5
                            Rectangle { width: 6; height: 6; radius: 3; color: "#f59e0b"; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Standard"; color: "#f59e0b"; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }

                    // Applied count pill
                    Rectangle {
                        width: applRow.width + 16; height: 28; radius: 6
                        color: "#12172b"
                        border.color: "#1c2333"; border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: applRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: appController.appliedCount + ""; color: "#22d3ee"; font.pixelSize: 11; font.weight: Font.Bold }
                            Text { text: "active"; color: "#4a5568"; font.pixelSize: 10 }
                        }
                    }

                    // Version
                    Text {
                        text: "v2.1"
                        color: "#2d3748"
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
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

    Cs2PathDialog { id: cs2PathDialog }

    // ── Restart Dialog (Centered Modal) ──
    Dialog {
        id: restartDialog
        anchors.centerIn: parent
        width: 400
        modal: true
        title: ""

        background: Rectangle {
            radius: 16
            color: "#12172b"
            border.color: "#1c2333"
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 17
                color: "transparent"
                border.color: "#06b6d4"
                border.width: 1
                opacity: 0.15
            }
        }

        contentItem: ColumnLayout {
            spacing: 16

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 48; radius: 24
                color: "#0e2a3d"
                border.color: "#06b6d4"; border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\u21BB"
                    font.pixelSize: 20
                    color: "#22d3ee"
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Restart Required"
                color: "#f0f6ff"
                font.pixelSize: 20
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Tweaks saved and applied.\nRestart your system for changes to take effect."
                color: "#7b8ba3"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                lineHeight: 1.4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.topMargin: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 40; radius: 10
                    color: "transparent"
                    border.color: "#1c2333"; border.width: 1

                    Text { anchors.centerIn: parent; text: "Later"; color: "#7b8ba3"; font.pixelSize: 13; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: restartDialog.close() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40; radius: 10
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

    // ═══════ Inline Nav Tab Component ═══════
    component NavTab: Rectangle {
        property string label: ""
        property string icon: ""
        property int tabIndex: 0
        property bool active: root.currentPage === tabIndex

        width: tabRow.width + 28
        height: 38
        radius: 8
        color: active ? "#1a2744" : tabHover.containsMouse ? "#131a2b" : "transparent"

        Row {
            id: tabRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                text: icon
                font.pixelSize: 13
                color: active ? "#22d3ee" : "#4a5568"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: label
                font.pixelSize: 12
                font.weight: active ? Font.Bold : Font.DemiBold
                color: active ? "#e0f7ff" : "#7b8ba3"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Active underline
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 12
            height: 2
            radius: 1
            color: "#06b6d4"
            visible: active
        }

        MouseArea {
            id: tabHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentPage = tabIndex
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
