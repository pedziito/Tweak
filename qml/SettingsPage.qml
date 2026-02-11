import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hone-style Settings / Control Panel page
Flickable {
    id: settingsRoot
    contentWidth: width; contentHeight: settingsCol.implicitHeight + 56
    clip: true; boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    property int activeSection: 0 // 0=General, 1=About, 2=Support

    ColumnLayout {
        id: settingsCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 28; spacing: 20

        // Header
        ColumnLayout {
            spacing: 4
            Text { text: "Settings"; color: "#f0f6ff"; font.pixelSize: 26; font.weight: Font.Bold }
            Text { text: "Configure preferences, view system information, and get support"; color: "#5a6a7c"; font.pixelSize: 12 }
        }

        // Section tabs
        Row {
            spacing: 0
            Repeater {
                model: ["General", "About", "Support"]
                delegate: Rectangle {
                    width: tabLabel.width + 32; height: 38; radius: 8
                    color: settingsRoot.activeSection === index ? "#f59e0b" : stHover.containsMouse ? "#111827" : "transparent"
                    Text {
                        id: tabLabel; anchors.centerIn: parent
                        text: modelData; color: settingsRoot.activeSection === index ? "#000" : "#7b8ba3"
                        font.pixelSize: 12; font.weight: Font.Bold
                    }
                    MouseArea { id: stHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: settingsRoot.activeSection = index }
                }
            }
        }

        // ═══════ GENERAL SETTINGS ═══════
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            visible: settingsRoot.activeSection === 0

            SettingsSection {
                title: "Application"

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0

                    SettingToggle { label: "Start with Windows"; desc: "Automatically launch Tweak when Windows starts"; toggled: false }
                    SettingToggle { label: "Start minimized"; desc: "Start the application minimized to system tray"; toggled: false }
                    SettingToggle { label: "Auto-apply on startup"; desc: "Automatically apply saved optimizations when the app starts"; toggled: false }
                    SettingToggle { label: "Show notifications"; desc: "Display system notifications for optimization status"; toggled: true }
                    SettingToggle { label: "Dark mode"; desc: "Use dark theme for the application interface"; toggled: true }
                }
            }

            SettingsSection {
                title: "Performance Monitoring"

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0

                    SettingToggle { label: "Real-time monitoring"; desc: "Enable CPU, GPU, and RAM usage monitoring in the dashboard"; toggled: true }
                    SettingToggle { label: "Low resource mode"; desc: "Reduce monitoring frequency to minimize system impact"; toggled: false }

                    // Monitor interval
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 52; color: "transparent"
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0d1220" }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Update interval"; color: "#c5d0de"; font.pixelSize: 13 }
                                Text { text: "How often system stats refresh"; color: "#5a6a7c"; font.pixelSize: 11 }
                            }
                            Text { text: "2 seconds"; color: "#f59e0b"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                    }
                }
            }

            SettingsSection {
                title: "Data & Storage"

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0

                    SettingToggle { label: "Save tweak history"; desc: "Keep a log of applied and reverted optimizations"; toggled: true }

                    // CS2 Path
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 52; color: "transparent"
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0d1220" }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "CS2 Install Path"; color: "#c5d0de"; font.pixelSize: 13 }
                                Text { text: appController.cs2Path || "Not set"; color: "#5a6a7c"; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.maximumWidth: 400 }
                            }
                            Rectangle {
                                width: browseLabel.width + 24; height: 30; radius: 6
                                color: "transparent"; border.color: "#1c2333"; border.width: 1
                                Text { id: browseLabel; anchors.centerIn: parent; text: "Browse"; color: "#06b6d4"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cs2PathDialog.open() }
                            }
                        }
                    }

                    // Reset all
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 52; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Reset all tweaks"; color: "#c5d0de"; font.pixelSize: 13 }
                                Text { text: "Restore all optimizations to Windows defaults"; color: "#5a6a7c"; font.pixelSize: 11 }
                            }
                            Rectangle {
                                width: resetLabel.width + 24; height: 30; radius: 6
                                color: "#1c0a0a"; border.color: "#7f1d1d"; border.width: 1
                                Text { id: resetLabel; anchors.centerIn: parent; text: "Reset All"; color: "#ef4444"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appController.restoreAll() }
                            }
                        }
                    }
                }
            }
        }

        // ═══════ ABOUT SECTION ═══════
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            visible: settingsRoot.activeSection === 1

            // App info card
            Rectangle {
                Layout.fillWidth: true; implicitHeight: aboutCol.implicitHeight + 40
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    id: aboutCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 20; spacing: 16

                    RowLayout {
                        spacing: 16
                        Rectangle {
                            width: 56; height: 56; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#f59e0b" }
                                GradientStop { position: 1.0; color: "#fbbf24" }
                            }
                            Text { anchors.centerIn: parent; text: "T"; font.pixelSize: 24; font.weight: Font.Black; color: "#fff" }
                        }
                        ColumnLayout {
                            spacing: 4
                            Text { text: "Tweak"; color: "#f0f6ff"; font.pixelSize: 22; font.weight: Font.Bold }
                            Text { text: "Version 4.1 · Built with Qt " + "6.x"; color: "#5a6a7c"; font.pixelSize: 12 }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                    Text {
                        Layout.fillWidth: true; wrapMode: Text.Wrap; lineHeight: 1.5
                        color: "#7b8ba3"; font.pixelSize: 12
                        text: "Tweak is a gaming performance optimizer built for Windows. It applies system-level optimizations to improve FPS, reduce input lag, and boost responsiveness. Optimizations are categorized as Basic, General, and Advanced — allowing both beginners and power users to tune their systems safely."
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 24; rowSpacing: 10
                        Text { text: "Platform"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "Windows 10/11"; color: "#c5d0de"; font.pixelSize: 12 }
                        Text { text: "Min RAM"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "4 GB"; color: "#c5d0de"; font.pixelSize: 12 }
                        Text { text: "Framework"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "Qt / QML / C++17"; color: "#c5d0de"; font.pixelSize: 12 }
                        Text { text: "Tweaks"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "92 optimizations"; color: "#c5d0de"; font.pixelSize: 12 }
                        Text { text: "License"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "Free to use"; color: "#22c55e"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                }
            }

            // System info
            Rectangle {
                Layout.fillWidth: true; implicitHeight: sysInfoCol.implicitHeight + 40
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    id: sysInfoCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 20; spacing: 12

                    Text { text: "Your System"; color: "#f0f6ff"; font.pixelSize: 16; font.weight: Font.Bold }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 24; rowSpacing: 10
                        Text { text: "CPU"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.cpuName || "Detecting..."; color: "#c5d0de"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Cores / Threads"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.cpuCores + " / " + appController.cpuThreads; color: "#c5d0de"; font.pixelSize: 12 }
                        Text { text: "GPU"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.gpuName || "Detecting..."; color: "#c5d0de"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "RAM"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.totalRam || "Detecting..."; color: "#c5d0de"; font.pixelSize: 12 }
                        Text { text: "Storage"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.diskModel || "Detecting..."; color: "#c5d0de"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Motherboard"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.motherboardName || "Detecting..."; color: "#c5d0de"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "OS"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.osVersion || "Detecting..."; color: "#c5d0de"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Admin"; color: "#4a5568"; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                        Text { text: appController.isAdmin ? "Yes" : "No (limited tweaks)"; color: appController.isAdmin ? "#22c55e" : "#f59e0b"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                }
            }

            // Updates
            Rectangle {
                Layout.fillWidth: true; implicitHeight: updateCol.implicitHeight + 32
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    id: updateCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 20; spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            Text { text: "Updates"; color: "#f0f6ff"; font.pixelSize: 16; font.weight: Font.Bold }
                            Text { text: "Tweak checks for updates automatically on startup"; color: "#5a6a7c"; font.pixelSize: 12 }
                        }
                        Rectangle {
                            width: checkLabel.width + 28; height: 34; radius: 8
                            color: "transparent"; border.color: "#1c2333"; border.width: 1
                            Text { id: checkLabel; anchors.centerIn: parent; text: "Check for Updates"; color: "#06b6d4"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 8; color: "#052e16"; border.color: "#166534"; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8
                            Canvas {
                                width: 16; height: 16
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 2; ctx.lineCap = "round"
                                    ctx.beginPath(); ctx.moveTo(3, 9); ctx.lineTo(6, 12); ctx.lineTo(13, 4); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }
                            Text { text: "You're running the latest version (v4.1)"; color: "#22c55e"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }

        // ═══════ SUPPORT SECTION ═══════
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            visible: settingsRoot.activeSection === 2

            // Support cards
            Flow {
                Layout.fillWidth: true; spacing: 14

                SupportCard {
                    width: (parent.width - 28) / 3
                    iconType: "bug"; iconColor: "#ef4444"
                    title: "Report a Bug"
                    desc: "Found an issue? Send a bug report with system information and logs to help us fix it."
                    buttonText: "Send Report"
                }
                SupportCard {
                    width: (parent.width - 28) / 3
                    iconType: "chat"; iconColor: "#06b6d4"
                    title: "Discord Community"
                    desc: "Join our Discord server for support, feature requests, and to connect with other users."
                    buttonText: "Join Discord"
                }
                SupportCard {
                    width: (parent.width - 28) / 3
                    iconType: "book"; iconColor: "#f59e0b"
                    title: "Documentation"
                    desc: "Read the documentation to learn about all features, tweaks, and best practices."
                    buttonText: "View Docs"
                }
            }

            // FAQ
            SettingsSection {
                title: "Frequently Asked Questions"

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0

                    FaqItem {
                        question: "Is Tweak safe to use?"
                        answer: "Yes. All tweaks modify standard Windows registry settings and can be fully reverted. We recommend applying tweaks gradually and testing between changes."
                    }
                    FaqItem {
                        question: "Do I need admin rights?"
                        answer: "Some advanced tweaks require administrator privileges. Running as admin unlocks all 92 optimizations. Without admin, basic tweaks are still available."
                    }
                    FaqItem {
                        question: "Will this work with any game?"
                        answer: "System-level optimizations (network, power plan, visual effects) benefit all games. Game-specific settings in the Games section are tailored for popular titles."
                    }
                    FaqItem {
                        question: "How do I restore defaults?"
                        answer: "Go to Settings > General > Reset All or use the Restore button on the Dashboard shortcuts. This reverts all tweaks to Windows defaults."
                    }
                    FaqItem {
                        question: "Can I save my tweak configuration?"
                        answer: "Use the 'Saved' tab in Optimizations to see applied tweaks. You can also use presets via the Dashboard to save and load configurations."
                    }
                }
            }

            // System diagnostic
            Rectangle {
                Layout.fillWidth: true; implicitHeight: diagCol.implicitHeight + 32
                radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

                ColumnLayout {
                    id: diagCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 20; spacing: 12

                    Text { text: "Diagnostic Information"; color: "#f0f6ff"; font.pixelSize: 16; font.weight: Font.Bold }
                    Text { text: "This information can be included in bug reports to help diagnose issues."; color: "#5a6a7c"; font.pixelSize: 12 }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 120; radius: 8
                        color: "#0a0e1a"; border.color: "#141a2a"; border.width: 1
                        Flickable {
                            anchors.fill: parent; anchors.margins: 10; clip: true
                            contentHeight: diagText.implicitHeight
                            Text {
                                id: diagText; width: parent.width; wrapMode: Text.Wrap
                                color: "#5a6a7c"; font.pixelSize: 11; font.family: "monospace"; lineHeight: 1.6
                                text: "OS: " + (appController.osVersion || "N/A") + "\n" +
                                      "CPU: " + (appController.cpuName || "N/A") + " (" + appController.cpuCores + "C/" + appController.cpuThreads + "T)\n" +
                                      "GPU: " + (appController.gpuName || "N/A") + " (" + (appController.gpuVendor || "N/A") + ")\n" +
                                      "RAM: " + (appController.totalRam || "N/A") + "\n" +
                                      "Storage: " + (appController.diskModel || "N/A") + (appController.hasNvme ? " [NVMe]" : appController.hasSsd ? " [SSD]" : " [HDD]") + "\n" +
                                      "Admin: " + (appController.isAdmin ? "Yes" : "No") + "\n" +
                                      "Applied Tweaks: " + appController.appliedCount + " / 92\n" +
                                      "Version: 4.1"
                            }
                        }
                    }

                    Row {
                        spacing: 10
                        Rectangle {
                            width: copyLabel.width + 28; height: 34; radius: 8
                            color: "transparent"; border.color: "#1c2333"; border.width: 1
                            Text { id: copyLabel; anchors.centerIn: parent; text: "Copy to Clipboard"; color: "#06b6d4"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }

        Item { height: 20 }
    }

    // ── Components ──

    component SettingsSection: Rectangle {
        property string title: ""
        default property alias content: sectionContent.data
        Layout.fillWidth: true; implicitHeight: sectionInner.implicitHeight + 32
        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1
        ColumnLayout {
            id: sectionInner
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 16; spacing: 8
            Text { text: title; color: "#f0f6ff"; font.pixelSize: 16; font.weight: Font.Bold }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }
            ColumnLayout { id: sectionContent; Layout.fillWidth: true; spacing: 0 }
        }
    }

    component SettingToggle: Rectangle {
        property string label: ""
        property string desc: ""
        property bool toggled: false
        Layout.fillWidth: true; implicitHeight: 52; color: "transparent"
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0d1220" }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: label; color: "#c5d0de"; font.pixelSize: 13 }
                Text { text: desc; color: "#5a6a7c"; font.pixelSize: 11 }
            }
            Switch {
                checked: toggled
                indicator: Rectangle {
                    implicitWidth: 40; implicitHeight: 22; radius: 11
                    color: parent.checked ? "#0d3a4a" : "#1c2333"
                    border.color: parent.checked ? "#06b6d4" : "#2d3748"; border.width: 1
                    Rectangle {
                        x: parent.parent.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: parent.parent.checked ? "#22d3ee" : "#4a5568"
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                }
            }
        }
    }

    component SupportCard: Rectangle {
        property string iconType: ""
        property color iconColor: "#06b6d4"
        property string title: ""
        property string desc: ""
        property string buttonText: ""
        height: 200; radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1; clip: true
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            Canvas {
                width: 28; height: 28
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = iconColor; ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"
                    if (iconType === "bug") {
                        ctx.beginPath(); ctx.roundedRect(8, 8, 12, 14, 6, 6); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(8, 13); ctx.lineTo(4, 11); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(20, 13); ctx.lineTo(24, 11); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(8, 18); ctx.lineTo(4, 20); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(20, 18); ctx.lineTo(24, 20); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(10, 8); ctx.lineTo(9, 4); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(18, 8); ctx.lineTo(19, 4); ctx.stroke()
                    } else if (iconType === "chat") {
                        ctx.beginPath(); ctx.roundedRect(3, 3, 22, 16, 4, 4); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(8, 19); ctx.lineTo(8, 25); ctx.lineTo(14, 19); ctx.stroke()
                    } else if (iconType === "book") {
                        ctx.beginPath(); ctx.moveTo(4, 3); ctx.lineTo(4, 23); ctx.quadraticCurveTo(4, 25, 8, 25); ctx.lineTo(24, 25); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(4, 3); ctx.quadraticCurveTo(4, 3, 8, 3); ctx.lineTo(24, 3); ctx.lineTo(24, 25); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(4, 21); ctx.quadraticCurveTo(4, 21, 8, 21); ctx.lineTo(24, 21); ctx.stroke()
                    }
                }
                Component.onCompleted: requestPaint()
            }
            Text { text: title; color: "#f0f6ff"; font.pixelSize: 15; font.weight: Font.Bold }
            Text { text: desc; color: "#5a6a7c"; font.pixelSize: 12; wrapMode: Text.Wrap; lineHeight: 1.4; Layout.fillWidth: true }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 8
                color: "transparent"; border.color: "#1c2333"; border.width: 1
                Text { anchors.centerIn: parent; text: buttonText; color: "#06b6d4"; font.pixelSize: 12; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    component FaqItem: Rectangle {
        property string question: ""
        property string answer: ""
        property bool expanded: false
        Layout.fillWidth: true; implicitHeight: faqInner.implicitHeight + 16; color: "transparent"; clip: true
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0d1220" }
        ColumnLayout {
            id: faqInner; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Text { text: question; color: "#c5d0de"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                Text {
                    text: expanded ? "−" : "+"; color: "#7b8ba3"; font.pixelSize: 16; font.weight: Font.Bold
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: expanded = !expanded }
                }
            }
            Text {
                visible: expanded; text: answer; color: "#5a6a7c"; font.pixelSize: 12
                wrapMode: Text.Wrap; lineHeight: 1.5; Layout.fillWidth: true
            }
        }
    }
}
