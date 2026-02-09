import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: "Tweak  —  Performance Tuner"

    Material.theme: Material.Dark
    Material.accent: "#5ad6ff"
    Material.primary: "#14181f"
    Material.background: "#0c1017"

    font.family: "Segoe UI"
    font.pixelSize: 13

    // ── Background gradient ──
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#090d12" }
            GradientStop { position: 0.5; color: "#0e1319" }
            GradientStop { position: 1.0; color: "#0b0f14" }
        }
    }

    // ── Top bar ──
    header: ToolBar {
        Material.background: "#0f141b"
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 16

            Text {
                text: "⚡ TWEAK"
                font.pixelSize: 18
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: "#5ad6ff"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: appController.appliedCount + " / " + appController.recommendedCount + " applied"
                color: "#8aa3b8"
                font.pixelSize: 12
            }

            Rectangle {
                width: 8; height: 8; radius: 4
                color: appController.isAdmin ? "#5ee87d" : "#ff9f43"
            }
            Text {
                text: appController.isAdmin ? "Admin" : "User"
                color: appController.isAdmin ? "#5ee87d" : "#ff9f43"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Button {
                visible: !appController.isAdmin
                text: "Elevate"
                flat: true
                font.pixelSize: 11
                onClicked: {
                    if (appController.requestAdmin())
                        Qt.quit()
                }
            }
        }
    }

    // ── Main layout ──
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Left sidebar
        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            spacing: 16

            HardwarePanel {}

            QuickActionsPanel {}

            StartupPanel {
                Layout.fillHeight: true
            }
        }

        // Right content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Category filter + title
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Performance Tweaks"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: "#e6edf6"
                    }
                    Text {
                        text: "Safe, reversible registry & system optimizations"
                        font.pixelSize: 12
                        color: "#6b8299"
                    }
                }

                CategoryFilter {
                    id: categoryFilter
                }
            }

            // Tweak list
            ListView {
                id: tweaksList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: appController.tweaksModel
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                section.property: "category"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    width: tweaksList.width
                    height: visible ? 36 : 0
                    visible: categoryFilter.currentCategory === "All"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▸  " + section
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                        color: "#5e7a93"
                        font.capitalization: Font.AllUppercase
                    }
                }

                delegate: TweakCard {
                    width: tweaksList.width
                    visible: categoryFilter.currentCategory === "All"
                             || category === categoryFilter.currentCategory
                    height: visible ? implicitHeight : 0
                }
            }
        }
    }

    // CS2 path dialog
    Cs2PathDialog { id: cs2PathDialog }
}
