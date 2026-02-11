import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hone-style Boost-Up page — disk cleanup, cache clearing, system maintenance
Flickable {
    id: boostRoot
    contentWidth: width; contentHeight: boostCol.implicitHeight + 56
    clip: true; boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    // State tracking
    property bool scanning: false
    property bool cleaned: false
    property double tempSize: 0
    property double dnsStatus: 0
    property double thumbSize: 0
    property double logSize: 0
    property double totalFreed: 0

    ListModel {
        id: boostItemsModel
        ListElement { name: "Temporary Files"; desc: "Windows temp files, browser cache, and temporary data"; icon: "folder"; size: "Scanning..."; status: "idle"; accent: "#06b6d4" }
        ListElement { name: "DNS Cache"; desc: "Flush DNS resolver cache to fix connectivity issues"; icon: "globe"; size: "Ready"; status: "idle"; accent: "#22c55e" }
        ListElement { name: "Thumbnail Cache"; desc: "Windows Explorer thumbnail database and image cache"; icon: "image"; size: "Scanning..."; status: "idle"; accent: "#f59e0b" }
        ListElement { name: "System Logs"; desc: "Old Windows event logs and crash dump files"; icon: "file"; size: "Scanning..."; status: "idle"; accent: "#8b5cf6" }
        ListElement { name: "Prefetch Data"; desc: "Application prefetch cache used for faster startup"; icon: "zap"; size: "Scanning..."; status: "idle"; accent: "#ef4444" }
        ListElement { name: "Windows Update Cache"; desc: "Old Windows Update downloaded files and patches"; icon: "download"; size: "Scanning..."; status: "idle"; accent: "#06b6d4" }
        ListElement { name: "Recycle Bin"; desc: "Permanently delete items in the recycle bin"; icon: "trash"; size: "Scanning..."; status: "idle"; accent: "#f43f5e" }
        ListElement { name: "Shader Cache"; desc: "GPU shader compilation cache (DirectX & Vulkan)"; icon: "gpu"; size: "Scanning..."; status: "idle"; accent: "#fbbf24" }
    }

    Timer {
        id: scanTimer; interval: 1200; running: false
        onTriggered: {
            // Simulate scan results
            boostItemsModel.setProperty(0, "size", "247 MB")
            boostItemsModel.setProperty(1, "size", "Ready")
            boostItemsModel.setProperty(2, "size", "89 MB")
            boostItemsModel.setProperty(3, "size", "156 MB")
            boostItemsModel.setProperty(4, "size", "34 MB")
            boostItemsModel.setProperty(5, "size", "512 MB")
            boostItemsModel.setProperty(6, "size", "78 MB")
            boostItemsModel.setProperty(7, "size", "203 MB")
            boostRoot.scanning = false
        }
    }

    Component.onCompleted: {
        scanning = true
        scanTimer.start()
    }

    ColumnLayout {
        id: boostCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 28; spacing: 20

        // Header
        ColumnLayout {
            spacing: 4
            Text { text: "Boost-Up"; color: "#f0f6ff"; font.pixelSize: 26; font.weight: Font.Bold }
            Text { text: "Free up disk space, clear caches and optimize system performance"; color: "#5a6a7c"; font.pixelSize: 12 }
        }

        // Stats row
        RowLayout {
            Layout.fillWidth: true; spacing: 14

            BoostStatCard {
                Layout.fillWidth: true
                title: "Total Freed"; value: boostRoot.cleaned ? "1.32 GB" : "—"
                accent: "#22c55e"; iconType: "check"
            }
            BoostStatCard {
                Layout.fillWidth: true
                title: "Items Found"; value: scanning ? "Scanning..." : "8"
                accent: "#06b6d4"; iconType: "search"
            }
            BoostStatCard {
                Layout.fillWidth: true
                title: "Disk Health"; value: Math.round(100 - appController.systemMonitor.storageUsage) + "% Free"
                accent: "#f59e0b"; iconType: "disk"
            }
            BoostStatCard {
                Layout.fillWidth: true
                title: "Last Cleanup"; value: boostRoot.cleaned ? "Just now" : "Never"
                accent: "#8b5cf6"; iconType: "clock"
            }
        }

        // Action buttons row
        RowLayout {
            Layout.fillWidth: true; spacing: 12

            Rectangle {
                Layout.preferredWidth: 160; height: 42; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#06b6d4" }
                    GradientStop { position: 1.0; color: "#0ea5e9" }
                }
                opacity: scanning ? 0.5 : 1.0

                Row {
                    anchors.centerIn: parent; spacing: 8
                    Canvas {
                        width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = "#fff"; ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"
                            ctx.beginPath(); ctx.moveTo(8, 1); ctx.lineTo(3, 9); ctx.lineTo(7, 9)
                            ctx.lineTo(6, 15); ctx.lineTo(13, 6); ctx.lineTo(9, 6); ctx.closePath(); ctx.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }
                    Text { text: "Clean All"; color: "#fff"; font.pixelSize: 13; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: scanning ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!scanning) {
                            appController.clearTempFiles()
                            boostRoot.cleaned = true
                            for (var i = 0; i < boostItemsModel.count; i++) {
                                boostItemsModel.setProperty(i, "status", "done")
                                boostItemsModel.setProperty(i, "size", "Cleaned")
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 130; height: 42; radius: 10
                color: "transparent"; border.color: "#1c2333"; border.width: 1

                Row {
                    anchors.centerIn: parent; spacing: 8
                    Canvas {
                        width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = "#7b8ba3"; ctx.lineWidth = 1.4; ctx.lineCap = "round"
                            ctx.beginPath(); ctx.arc(7, 7, 5.5, -0.5, Math.PI * 1.5); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(10, 1.5); ctx.lineTo(12.5, 3.5); ctx.lineTo(10, 5.5); ctx.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }
                    Text { text: "Re-scan"; color: "#7b8ba3"; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        boostRoot.scanning = true
                        boostRoot.cleaned = false
                        for (var i = 0; i < boostItemsModel.count; i++) {
                            boostItemsModel.setProperty(i, "status", "idle")
                            boostItemsModel.setProperty(i, "size", "Scanning...")
                        }
                        scanTimer.restart()
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 140; height: 42; radius: 10
                color: "transparent"; border.color: "#1c2333"; border.width: 1

                Row {
                    anchors.centerIn: parent; spacing: 8
                    Canvas {
                        width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 1.4; ctx.lineCap = "round"
                            ctx.beginPath(); ctx.arc(7, 7, 5.5, 0, Math.PI * 2); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(7, 4); ctx.lineTo(7, 7.5); ctx.lineTo(10, 9); ctx.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }
                    Text { text: "Flush DNS"; color: "#22c55e"; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appController.flushDns() }
            }

            Item { Layout.fillWidth: true }
        }

        // ═══════ BOOST ITEMS LIST ═══════
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: boostListCol.implicitHeight + 28
            radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

            ColumnLayout {
                id: boostListCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 14; spacing: 0

                // Header
                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 8
                    Text { text: "Cleanup Items"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold; Layout.fillWidth: true }
                    Text { text: "STATUS"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold; Layout.preferredWidth: 80 }
                    Text { text: "SIZE"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                Repeater {
                    model: boostItemsModel
                    delegate: Rectangle {
                        Layout.fillWidth: true; implicitHeight: 64
                        color: biHover.containsMouse ? "#111827" : "transparent"
                        radius: 6

                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0d1220" }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 12

                            // Icon
                            Rectangle {
                                width: 36; height: 36; radius: 8
                                color: Qt.rgba(0, 0, 0, 0); border.color: model.accent; border.width: 1
                                Layout.alignment: Qt.AlignVCenter

                                Canvas {
                                    anchors.centerIn: parent; width: 18; height: 18
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = model.accent; ctx.fillStyle = model.accent
                                        ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        if (model.icon === "folder") {
                                            ctx.beginPath(); ctx.moveTo(1, 4); ctx.lineTo(1, 15); ctx.lineTo(17, 15); ctx.lineTo(17, 6); ctx.lineTo(9, 6); ctx.lineTo(7, 4); ctx.closePath(); ctx.stroke()
                                        } else if (model.icon === "globe") {
                                            ctx.beginPath(); ctx.arc(9, 9, 7, 0, Math.PI * 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(2, 9); ctx.lineTo(16, 9); ctx.stroke()
                                            ctx.beginPath(); ctx.ellipse(5, 2, 8, 14); ctx.stroke()
                                        } else if (model.icon === "image") {
                                            ctx.beginPath(); ctx.roundedRect(1, 2, 16, 14, 2, 2); ctx.stroke()
                                            ctx.beginPath(); ctx.arc(6, 7, 2, 0, Math.PI * 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(1, 13); ctx.lineTo(6, 9); ctx.lineTo(10, 13); ctx.lineTo(13, 10); ctx.lineTo(17, 13); ctx.stroke()
                                        } else if (model.icon === "file") {
                                            ctx.beginPath(); ctx.moveTo(3, 1); ctx.lineTo(11, 1); ctx.lineTo(15, 5); ctx.lineTo(15, 17); ctx.lineTo(3, 17); ctx.closePath(); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(11, 1); ctx.lineTo(11, 5); ctx.lineTo(15, 5); ctx.stroke()
                                        } else if (model.icon === "zap") {
                                            ctx.beginPath(); ctx.moveTo(10, 1); ctx.lineTo(4, 9); ctx.lineTo(8, 9); ctx.lineTo(7, 17); ctx.lineTo(14, 8); ctx.lineTo(10, 8); ctx.closePath(); ctx.stroke()
                                        } else if (model.icon === "download") {
                                            ctx.beginPath(); ctx.moveTo(9, 2); ctx.lineTo(9, 12); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(5, 9); ctx.lineTo(9, 13); ctx.lineTo(13, 9); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(2, 14); ctx.lineTo(2, 16); ctx.lineTo(16, 16); ctx.lineTo(16, 14); ctx.stroke()
                                        } else if (model.icon === "trash") {
                                            ctx.beginPath(); ctx.moveTo(2, 4); ctx.lineTo(16, 4); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(6, 4); ctx.lineTo(6, 2); ctx.lineTo(12, 2); ctx.lineTo(12, 4); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(3, 4); ctx.lineTo(4, 16); ctx.lineTo(14, 16); ctx.lineTo(15, 4); ctx.stroke()
                                        } else if (model.icon === "gpu") {
                                            ctx.beginPath(); ctx.roundedRect(2, 4, 14, 10, 2, 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(5, 4); ctx.lineTo(5, 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(9, 4); ctx.lineTo(9, 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(13, 4); ctx.lineTo(13, 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(5, 14); ctx.lineTo(5, 16); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(9, 14); ctx.lineTo(9, 16); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(13, 14); ctx.lineTo(13, 16); ctx.stroke()
                                        }
                                    }
                                    Component.onCompleted: requestPaint()
                                }
                            }

                            // Name + desc
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2; Layout.alignment: Qt.AlignVCenter
                                Text { text: model.name; color: "#f0f6ff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { text: model.desc; color: "#5a6a7c"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                            }

                            // Status badge
                            Rectangle {
                                Layout.preferredWidth: 70; height: 24; radius: 6; Layout.alignment: Qt.AlignVCenter
                                color: model.status === "done" ? "#052e16" : "#0c1527"
                                border.color: model.status === "done" ? "#166534" : "#1c2333"; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: model.status === "done" ? "Cleaned" : (scanning ? "Scanning" : "Ready")
                                    color: model.status === "done" ? "#22c55e" : "#7b8ba3"
                                    font.pixelSize: 10; font.weight: Font.DemiBold
                                }
                            }

                            // Size
                            Text {
                                Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight
                                text: model.size; color: model.status === "done" ? "#22c55e" : "#c5d0de"
                                font.pixelSize: 12; font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea { id: biHover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true; onPressed: function(m){m.accepted=false} }
                    }
                }
            }
        }

        Item { height: 20 }
    }

    // ── BoostStatCard component ──
    component BoostStatCard: Rectangle {
        property string title: ""
        property string value: ""
        property color accent: "#06b6d4"
        property string iconType: "check"

        height: 100; radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 6

            RowLayout {
                spacing: 8
                Canvas {
                    width: 18; height: 18
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.strokeStyle = accent; ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"
                        if (iconType === "check") {
                            ctx.lineWidth = 2.5; ctx.beginPath(); ctx.moveTo(3, 10); ctx.lineTo(7, 14); ctx.lineTo(15, 4); ctx.stroke()
                        } else if (iconType === "search") {
                            ctx.beginPath(); ctx.arc(8, 8, 5, 0, Math.PI * 2); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(12, 12); ctx.lineTo(16, 16); ctx.stroke()
                        } else if (iconType === "disk") {
                            ctx.beginPath(); ctx.ellipse(1, 4, 16, 10); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(1, 9); ctx.lineTo(17, 9); ctx.stroke()
                        } else if (iconType === "clock") {
                            ctx.beginPath(); ctx.arc(9, 9, 7, 0, Math.PI * 2); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(9, 5); ctx.lineTo(9, 9); ctx.lineTo(13, 11); ctx.stroke()
                        }
                    }
                    Component.onCompleted: requestPaint()
                }
                Text { text: title; color: "#7b8ba3"; font.pixelSize: 11; font.weight: Font.Bold }
            }

            Item { Layout.fillHeight: true }

            Text { text: value; color: "#f0f6ff"; font.pixelSize: 20; font.weight: Font.Bold }
        }
    }
}
