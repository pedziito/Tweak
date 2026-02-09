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
            }

            // Page 2: Performance Benchmark
            PerformanceGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // CS2 path dialog
    Cs2PathDialog { id: cs2PathDialog }
}
