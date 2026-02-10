import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: sidebar
    width: 240
    color: "#0c1221"

    property int currentPage: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Logo ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 72

            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    width: 36; height: 36; radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#6366f1" }
                        GradientStop { position: 1.0; color: "#8b5cf6" }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\u26A1"
                        font.pixelSize: 16
                        color: "#ffffff"
                    }
                }
                Column {
                    spacing: 1
                    Text {
                        text: "Tweak"
                        color: "#f1f5f9"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                    }
                    Text {
                        text: "PERFORMANCE SUITE"
                        color: "#6366f1"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 3
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true; height: 1; color: "#1e293b"
            Layout.leftMargin: 16; Layout.rightMargin: 16
        }

        Item { Layout.preferredHeight: 20 }

        // OVERVIEW
        SectionLabel { label: "OVERVIEW" }
        Item { Layout.preferredHeight: 4 }

        NavButton {
            Layout.fillWidth: true
            text: "Dashboard"
            icon: "\u25A3"
            active: sidebar.currentPage === 0
            onClicked: sidebar.currentPage = 0
        }

        Item { Layout.preferredHeight: 16 }

        // OPTIMIZE
        SectionLabel { label: "OPTIMIZE" }
        Item { Layout.preferredHeight: 4 }

        NavButton {
            Layout.fillWidth: true
            text: "All Tweaks"
            icon: "\u2699"
            active: sidebar.currentPage === 1 && appController.selectedCategory === "All"
            badge: appController.appliedCount > 0 ? appController.appliedCount.toString() : ""
            onClicked: {
                sidebar.currentPage = 1
                appController.selectedCategory = "All"
            }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Gaming"
            icon: "\u25CE"
            active: sidebar.currentPage === 1 && appController.selectedCategory === "Gaming"
            onClicked: { sidebar.currentPage = 1; appController.selectedCategory = "Gaming" }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Network"
            icon: "\u25C9"
            active: sidebar.currentPage === 1 && appController.selectedCategory === "Network"
            onClicked: { sidebar.currentPage = 1; appController.selectedCategory = "Network" }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Privacy"
            icon: "\u25C6"
            active: sidebar.currentPage === 1 && appController.selectedCategory === "Privacy"
            onClicked: { sidebar.currentPage = 1; appController.selectedCategory = "Privacy" }
        }
        NavButton {
            Layout.fillWidth: true
            text: "Power"
            icon: "\u26A1"
            active: sidebar.currentPage === 1 && appController.selectedCategory === "Power"
            onClicked: { sidebar.currentPage = 1; appController.selectedCategory = "Power" }
        }

        Item { Layout.preferredHeight: 16 }

        // BENCHMARK
        SectionLabel { label: "BENCHMARK" }
        Item { Layout.preferredHeight: 4 }

        NavButton {
            Layout.fillWidth: true
            text: "Performance"
            icon: "\u25B2"
            active: sidebar.currentPage === 2
            onClicked: sidebar.currentPage = 2
        }
        NavButton {
            Layout.fillWidth: true
            text: "Game Estimator"
            icon: "\u25C8"
            active: sidebar.currentPage === 3
            onClicked: sidebar.currentPage = 3
        }

        Item { Layout.fillHeight: true }

        // ── Bottom ──
        Rectangle {
            Layout.fillWidth: true; height: 1; color: "#1e293b"
            Layout.leftMargin: 16; Layout.rightMargin: 16
        }

        Item { Layout.preferredHeight: 12 }

        // Admin status
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            height: 36
            radius: 10
            color: appController.isAdmin ? "#052e16" : "#451a03"
            border.color: appController.isAdmin ? "#166534" : "#92400e"
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: appController.isAdmin ? "#22c55e" : "#f59e0b"
                }
                Text {
                    text: appController.isAdmin ? "Administrator" : "Standard User"
                    color: appController.isAdmin ? "#22c55e" : "#f59e0b"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        // Elevate button
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: 38
            Layout.topMargin: 8
            radius: 10
            visible: !appController.isAdmin
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#6366f1" }
                GradientStop { position: 1.0; color: "#8b5cf6" }
            }

            Text {
                anchors.centerIn: parent
                text: "\u25B6  Run as Admin"
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.Bold
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

        // Version
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            text: "v2.0.0"
            color: "#475569"
            font.pixelSize: 10
        }

        Item { Layout.preferredHeight: 16 }
    }

    // ── Components ──
    component SectionLabel: Text {
        property string label: ""
        Layout.leftMargin: 20
        text: label
        color: "#475569"
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 2.5
    }

    component NavButton: Rectangle {
        property string text: ""
        property string icon: ""
        property bool active: false
        property string badge: ""
        signal clicked()

        height: 38
        color: active ? "#1e1b4b" : hoverArea.containsMouse ? "#111827" : "transparent"
        radius: 8
        Layout.leftMargin: 10
        Layout.rightMargin: 10

        // Active indicator
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: -2
            width: 3
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            radius: 2
            color: "#6366f1"
            visible: parent.active

            // Glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 5
                color: "#6366f1"
                opacity: 0.2
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: parent.parent.icon
                font.pixelSize: 14
                color: parent.parent.active ? "#a5b4fc" : "#64748b"
            }
            Text {
                text: parent.parent.text
                color: parent.parent.active ? "#e0e7ff" : "#94a3b8"
                font.pixelSize: 13
                font.weight: parent.parent.active ? Font.DemiBold : Font.Normal
                Layout.fillWidth: true
            }

            // Badge
            Rectangle {
                visible: parent.parent.badge !== ""
                width: badgeText.width + 12; height: 20; radius: 10
                color: "#312e81"
                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: parent.parent.parent.badge
                    color: "#a5b4fc"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
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
