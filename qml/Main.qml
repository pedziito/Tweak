import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: root
    width: 1440
    height: 900
    minimumWidth: 1100
    minimumHeight: 750
    visible: true
    title: "Tweak  —  Performance Suite"

    Material.theme: Material.Dark
    Material.accent: "#6366f1"
    Material.primary: "#0a0e1a"
    Material.background: "#0a0e1a"

    font.family: "Segoe UI"
    font.pixelSize: 13

    color: "#0a0e1a"

    // ── Background ──
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0e1a" }
            GradientStop { position: 0.3; color: "#0d1225" }
            GradientStop { position: 1.0; color: "#080c18" }
        }
    }

    // Subtle noise overlay for depth
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: 0.03
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#6366f1" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: "#06b6d4" }
            }
        }
    }

    // ── Root layout: Sidebar + Pages ──
    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.fillHeight: true
        }

        // Thin separator line
        Rectangle {
            Layout.fillHeight: true
            width: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: "#1e293b" }
                GradientStop { position: 0.8; color: "#1e293b" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Page content area
        StackLayout {
            id: pageStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: sidebar.currentPage

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

    // ── Restart Required Dialog ──
    Dialog {
        id: restartDialog
        anchors.centerIn: parent
        width: 420
        modal: true
        title: ""

        background: Rectangle {
            radius: 20
            color: "#111827"
            border.color: "#374151"
            border.width: 1

            // Glow effect
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 21
                color: "transparent"
                border.color: "#6366f1"
                border.width: 1
                opacity: 0.3
            }
        }

        contentItem: ColumnLayout {
            spacing: 20

            // Icon
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 56; height: 56; radius: 28
                color: "#1e1b4b"
                border.color: "#6366f1"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\u21BB"
                    font.pixelSize: 24
                    color: "#818cf8"
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Restart Required"
                color: "#f1f5f9"
                font.pixelSize: 22
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Your tweaks have been saved and applied.\nA system restart is needed for all changes to take effect."
                color: "#94a3b8"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                lineHeight: 1.4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 44; radius: 12
                    color: "transparent"
                    border.color: "#374151"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Later"
                        color: "#94a3b8"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: restartDialog.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44; radius: 12
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#6366f1" }
                        GradientStop { position: 1.0; color: "#8b5cf6" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Restart Now"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }
}
