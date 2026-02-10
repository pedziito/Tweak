import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Left sidebar navigation
Rectangle {
    id: sidebar
    width: 250
    color: "#110c1f"
    border.width: 0

    property int currentPage: 0  // 0=Home, 1=Tweaks, 2=Performance, 3=Game Benchmark

    // Right border accent
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: "#2a1f50"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // ── Logo area ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "transparent"

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                // Logo icon
                Rectangle {
                    width: 42; height: 42; radius: 14
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#7c3aed" }
                        GradientStop { position: 1.0; color: "#d946ef" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "⚡"
                        font.pixelSize: 20
                    }
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Tweak"
                        color: "#f0eaff"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }
                    Text {
                        text: "PERFORMANCE SUITE"
                        color: "#6b5b95"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2
                    }
                }
            }
        }

        // ── Separator ──
        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1540"; Layout.leftMargin: 20; Layout.rightMargin: 20 }

        // ── Nav sections ──
        Item { Layout.preferredHeight: 16 }

        // MAIN section
        Text {
            text: "MAIN"
            color: "#4a3d70"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 2
            Layout.leftMargin: 24
        }

        Item { Layout.preferredHeight: 8 }

        NavButton {
            Layout.fillWidth: true
            text: "Home"
            icon: "🏠"
            active: sidebar.currentPage === 0
            onClicked: sidebar.currentPage = 0
        }

        Item { Layout.preferredHeight: 16 }

        // GENERAL section
        Text {
            text: "GENERAL"
            color: "#4a3d70"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 2
            Layout.leftMargin: 24
        }

        Item { Layout.preferredHeight: 8 }

        NavButton {
            Layout.fillWidth: true
            text: "Power Settings"
            icon: "⚡"
            active: false
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "Power"
            }
        }
        NavButton {
            Layout.fillWidth: true
            text: "RAM Optimizer"
            icon: "💾"
            active: false
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "FPS"
            }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Network Tools"
            icon: "🌐"
            active: false
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "Network"
            }
        }

        Item { Layout.preferredHeight: 16 }

        // TWEAKS section
        Text {
            text: "TWEAKS"
            color: "#4a3d70"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 2
            Layout.leftMargin: 24
        }

        Item { Layout.preferredHeight: 8 }

        NavButton {
            Layout.fillWidth: true
            text: "All Tweaks"
            icon: "🔧"
            active: sidebar.currentPage === 1
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "All"
            }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Gaming"
            icon: "🎮"
            active: false
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "Gaming"
            }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Privacy"
            icon: "🔒"
            active: false
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "Privacy"
            }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Performance"
            icon: "📊"
            active: sidebar.currentPage === 2
            onClicked: sidebar.currentPage = 2
        }
        NavButton {
            Layout.fillWidth: true
            text: "Game Estimator"
            icon: "🎯"
            active: sidebar.currentPage === 3
            onClicked: sidebar.currentPage = 3
        }

        Item { Layout.fillHeight: true }

        // ── Bottom area ──
        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1540"; Layout.leftMargin: 20; Layout.rightMargin: 20 }

        Item { Layout.preferredHeight: 12 }

        // Version info
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "v1.1.0  ·  " + (appController.isAdmin ? "✓ Admin" : "⚠ User")
            color: appController.isAdmin ? "#10b981" : "#f59e0b"
            font.pixelSize: 10
        }

        Item { Layout.preferredHeight: 8 }

        // Elevate button
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.preferredHeight: 36
            radius: 10
            visible: !appController.isAdmin
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#7c3aed" }
                GradientStop { position: 1.0; color: "#d946ef" }
            }

            Text {
                anchors.centerIn: parent
                text: "🛡️  Run as Admin"
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (appController.requestAdmin())
                        Qt.quit()
                }
            }
        }

        Item { Layout.preferredHeight: 16 }
    }

    // ── NavButton component ──
    component NavButton: Rectangle {
        property string text: ""
        property string icon: ""
        property bool active: false
        signal clicked()

        height: 40
        color: active ? "#1e1540" : hoverArea.containsMouse ? "#16112e" : "transparent"
        radius: 0

        // Active indicator
        Rectangle {
            anchors.left: parent.left
            width: 3
            height: parent.height
            radius: 2
            color: "#7c3aed"
            visible: parent.active
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 16
            spacing: 12

            Text {
                text: parent.parent.icon
                font.pixelSize: 15
            }
            Text {
                text: parent.parent.text
                color: parent.parent.active ? "#d4b8ff" : "#8b7db0"
                font.pixelSize: 13
                font.weight: parent.parent.active ? Font.DemiBold : Font.Normal
                Layout.fillWidth: true
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
