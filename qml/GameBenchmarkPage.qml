import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs

/// Hone-style Games library page — grid of game cover art cards
Flickable {
    id: gamesPage
    contentWidth: width
    contentHeight: mainCol.implicitHeight + 40
    clip: true; boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.5 }
        background: Rectangle { color: "transparent" }
    }

    property int editingIndex: -1

    FileDialog {
        id: gameImageDialog
        title: "Choose game cover image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp *.webp)"]
        onAccepted: {
            if (gamesPage.editingIndex >= 0 && gamesPage.editingIndex < gameListModel.count) {
                gameListModel.setProperty(gamesPage.editingIndex, "coverImage", selectedFile.toString())
            }
        }
    }

    ListModel {
        id: gameListModel
        ListElement { name: "Counter-Strike 2"; coverImage: ""; color: "#f59e0b" }
        ListElement { name: "Fortnite"; coverImage: ""; color: "#06b6d4" }
        ListElement { name: "Valorant"; coverImage: ""; color: "#ef4444" }
        ListElement { name: "Apex Legends"; coverImage: ""; color: "#dc2626" }
        ListElement { name: "Minecraft"; coverImage: ""; color: "#22c55e" }
        ListElement { name: "Roblox"; coverImage: ""; color: "#f59e0b" }
        ListElement { name: "GTA V"; coverImage: ""; color: "#8b5cf6" }
        ListElement { name: "League of Legends"; coverImage: ""; color: "#06b6d4" }
    }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 28; spacing: 20

        // Header
        ColumnLayout {
            spacing: 4
            Text { text: "Games"; color: "#f0f6ff"; font.pixelSize: 26; font.weight: Font.Bold }
            Text { text: "View pro settings, presets and in-game settings"; color: "#5a6a7c"; font.pixelSize: 12 }
        }

        // Library label + search
        RowLayout {
            Layout.fillWidth: true; spacing: 12

            Row {
                spacing: 8
                Canvas {
                    width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.fillStyle = "#f59e0b"
                        // Grid icon
                        ctx.fillRect(1, 1, 6, 6); ctx.fillRect(9, 1, 6, 6)
                        ctx.fillRect(1, 9, 6, 6); ctx.fillRect(9, 9, 6, 6)
                    }
                    Component.onCompleted: requestPaint()
                }
                Text { text: "Library"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
            }

            Item { Layout.fillWidth: true }

            // Search
            Canvas {
                width: 18; height: 18
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = "#5a6a7c"; ctx.lineWidth = 1.5; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(8, 8, 5.5, 0, Math.PI * 2); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(12, 12); ctx.lineTo(16, 16); ctx.stroke()
                }
                Component.onCompleted: requestPaint()
            }

            // Refresh
            Canvas {
                width: 18; height: 18
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = "#5a6a7c"; ctx.lineWidth = 1.5; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(9, 9, 6, -0.5, Math.PI * 1.5); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(12, 3); ctx.lineTo(15, 5); ctx.lineTo(12, 7); ctx.stroke()
                }
                Component.onCompleted: requestPaint()
            }
        }

        // ═══════ GAME CARDS GRID ═══════
        Flow {
            Layout.fillWidth: true; spacing: 14

            Repeater {
                model: gameListModel

                delegate: Rectangle {
                    id: gameCard
                    width: (mainCol.width - 70) / 6
                    height: width * 1.35
                    radius: 8; color: "#0c1120"; border.color: gcHover.containsMouse ? "#f59e0b" : "#141a2a"; border.width: 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Cover image or placeholder
                    Rectangle {
                        anchors.fill: parent; anchors.bottomMargin: 28; radius: 8
                        color: model.coverImage !== "" ? "transparent" : Qt.darker(model.color, 2.5)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: model.coverImage
                            visible: model.coverImage !== ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        // Placeholder when no image
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 8
                            visible: model.coverImage === ""

                            Canvas {
                                Layout.alignment: Qt.AlignHCenter; width: 40; height: 40
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.3); ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                    // Gamepad placeholder
                                    ctx.beginPath()
                                    ctx.moveTo(5, 16); ctx.quadraticCurveTo(5, 10, 12, 10)
                                    ctx.lineTo(16, 10); ctx.lineTo(16, 7); ctx.lineTo(24, 7); ctx.lineTo(24, 10); ctx.lineTo(28, 10)
                                    ctx.quadraticCurveTo(35, 10, 35, 16); ctx.lineTo(35, 24)
                                    ctx.quadraticCurveTo(35, 32, 30, 34); ctx.lineTo(28, 28); ctx.lineTo(12, 28); ctx.lineTo(10, 34)
                                    ctx.quadraticCurveTo(5, 32, 5, 24); ctx.closePath(); ctx.stroke()
                                    // X eyes
                                    ctx.lineWidth = 1.2
                                    ctx.beginPath(); ctx.moveTo(14, 17); ctx.lineTo(18, 21); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(18, 17); ctx.lineTo(14, 21); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(22, 17); ctx.lineTo(26, 21); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(26, 17); ctx.lineTo(22, 21); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Click to add\ncover image"
                                color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Hover overlay for changing image
                        Rectangle {
                            anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.6)
                            visible: gcHover.containsMouse
                            radius: 8

                            Canvas {
                                anchors.centerIn: parent; width: 24; height: 24
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = "#fff"; ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                    // Camera icon
                                    ctx.beginPath(); ctx.roundedRect(2, 6, 20, 14, 3, 3); ctx.stroke()
                                    ctx.beginPath(); ctx.arc(12, 14, 4, 0, Math.PI * 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(7, 6); ctx.lineTo(9, 3); ctx.lineTo(15, 3); ctx.lineTo(17, 6); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }
                        }
                    }

                    // Game name
                    Text {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 8
                        text: model.name; color: "#f59e0b"; font.pixelSize: 11; font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: gcHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            gamesPage.editingIndex = model.index
                            gameImageDialog.open()
                        }
                    }
                }
            }
        }

        Item { height: 20 }
    }
}
