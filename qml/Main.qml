import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: root
    width: 1360
    height: 860
    minimumWidth: 1040
    minimumHeight: 700
    visible: true
    title: "Tweak  —  Performance Suite"

    Material.theme: Material.Dark
    Material.accent: "#7c3aed"
    Material.primary: "#0f0a1a"
    Material.background: "#0f0a1a"

    font.family: "Segoe UI"
    font.pixelSize: 13

    color: "#0f0a1a"

    // ── Background ──
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f0a1a" }
            GradientStop { position: 0.4; color: "#110d1f" }
            GradientStop { position: 1.0; color: "#0d0816" }
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

        // Page content area
        StackLayout {
            id: pageStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: sidebar.currentPage

            // Page 0: Dashboard
            DashboardPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Page 1: Tweaks
            TweaksPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
                onRestartRequested: restartDialog.open()
            }

            // Page 2: Performance Benchmark
            PerformanceGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Page 3: Game FPS Estimator
            GameBenchmarkPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // CS2 path dialog
    Cs2PathDialog { id: cs2PathDialog }

    // ── Restart Required Dialog ──
    Dialog {
        id: restartDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        title: ""

        background: Rectangle {
            radius: 16
            color: "#1a1230"
            border.color: "#7c3aed"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: "Restart to Apply"
                color: "#f0eaff"
                font.pixelSize: 20
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Your tweaks have been saved.\nRestart your PC to apply the changes."
                color: "#8b7db0"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 8

                // Later button
                Rectangle {
                    Layout.fillWidth: true
                    height: 40; radius: 10
                    color: "transparent"
                    border.color: "#3b2960"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Later"
                        color: "#8b7db0"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: restartDialog.close()
                    }
                }

                // Restart Now button
                Rectangle {
                    Layout.fillWidth: true
                    height: 40; radius: 10
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#7c3aed" }
                        GradientStop { position: 1.0; color: "#d946ef" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Restart Now"
                        color: "#ffffff"
                        font.pixelSize: 13
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
