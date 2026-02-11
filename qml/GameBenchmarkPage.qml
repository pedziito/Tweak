import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs

/// Hone-style Games page — game library + pro profiles + in-game settings
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
    property int selectedGame: -1
    property int activeTab: 0 // 0=Library, 1=Pro Profiles, 2=Settings

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
        ListElement { name: "Counter-Strike 2"; coverImage: ""; color: "#f59e0b"; genre: "FPS"; proCount: 12 }
        ListElement { name: "Fortnite"; coverImage: ""; color: "#06b6d4"; genre: "Battle Royale"; proCount: 8 }
        ListElement { name: "Valorant"; coverImage: ""; color: "#ef4444"; genre: "FPS"; proCount: 15 }
        ListElement { name: "Apex Legends"; coverImage: ""; color: "#dc2626"; genre: "Battle Royale"; proCount: 6 }
        ListElement { name: "Minecraft"; coverImage: ""; color: "#22c55e"; genre: "Sandbox"; proCount: 3 }
        ListElement { name: "Roblox"; coverImage: ""; color: "#f59e0b"; genre: "Platform"; proCount: 2 }
        ListElement { name: "GTA V"; coverImage: ""; color: "#8b5cf6"; genre: "Open World"; proCount: 4 }
        ListElement { name: "League of Legends"; coverImage: ""; color: "#06b6d4"; genre: "MOBA"; proCount: 10 }
        ListElement { name: "Overwatch 2"; coverImage: ""; color: "#f97316"; genre: "FPS"; proCount: 9 }
        ListElement { name: "PUBG"; coverImage: ""; color: "#eab308"; genre: "Battle Royale"; proCount: 5 }
        ListElement { name: "Rocket League"; coverImage: ""; color: "#3b82f6"; genre: "Sports"; proCount: 7 }
        ListElement { name: "Call of Duty: Warzone"; coverImage: ""; color: "#4ade80"; genre: "FPS"; proCount: 11 }
    }

    // Pro player profiles data
    ListModel {
        id: proProfilesModel
        ListElement { player: "s1mple"; team: "NAVI"; game: "Counter-Strike 2"; dpi: "400"; sens: "3.09"; res: "1280x960"; hz: "360"; crosshair: "Classic Static" }
        ListElement { player: "ZywOo"; team: "Vitality"; game: "Counter-Strike 2"; dpi: "400"; sens: "2.0"; res: "1280x960"; hz: "360"; crosshair: "Classic Dynamic" }
        ListElement { player: "NiKo"; team: "G2"; game: "Counter-Strike 2"; dpi: "400"; sens: "1.38"; res: "1920x1080"; hz: "360"; crosshair: "Small Dot" }
        ListElement { player: "TenZ"; team: "Sentinels"; game: "Valorant"; dpi: "800"; sens: "0.4"; res: "1920x1080"; hz: "240"; crosshair: "Crosshair" }
        ListElement { player: "Shroud"; team: "Retired"; game: "Valorant"; dpi: "450"; sens: "0.78"; res: "1920x1080"; hz: "240"; crosshair: "Inner Lines" }
        ListElement { player: "Bugha"; team: "Sentinels"; game: "Fortnite"; dpi: "400"; sens: "11.0%"; res: "1920x1080"; hz: "240"; crosshair: "Default" }
        ListElement { player: "ImperialHal"; team: "TSM"; game: "Apex Legends"; dpi: "400"; sens: "2.8"; res: "1920x1080"; hz: "240"; crosshair: "Small Circle" }
        ListElement { player: "Faker"; team: "T1"; game: "League of Legends"; dpi: "3500"; sens: "50"; res: "1920x1080"; hz: "240"; crosshair: "N/A" }
        ListElement { player: "aceu"; team: "Retired"; game: "Apex Legends"; dpi: "400"; sens: "3.0"; res: "1920x1080"; hz: "240"; crosshair: "Dot" }
        ListElement { player: "Mongraal"; team: ""; game: "Fortnite"; dpi: "400"; sens: "8.0%"; res: "1920x1080"; hz: "240"; crosshair: "Default" }
    }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 28; spacing: 20

        // Header
        ColumnLayout {
            spacing: 4
            Text { text: "Games"; color: "#f0f6ff"; font.pixelSize: 26; font.weight: Font.Bold }
            Text { text: "Optimized settings, pro player profiles and in-game configurations"; color: "#5a6a7c"; font.pixelSize: 12 }
        }

        // Tab bar
        Row {
            spacing: 0
            Repeater {
                model: ["Library", "Pro Profiles", "Game Settings"]
                delegate: Rectangle {
                    width: gTabLabel.width + 32; height: 38; radius: 8
                    color: gamesPage.activeTab === index ? "#f59e0b" : gtHover.containsMouse ? "#111827" : "transparent"
                    Text {
                        id: gTabLabel; anchors.centerIn: parent
                        text: modelData; color: gamesPage.activeTab === index ? "#000" : "#7b8ba3"
                        font.pixelSize: 12; font.weight: Font.Bold
                    }
                    MouseArea { id: gtHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gamesPage.activeTab = index }
                }
            }
        }

        // ═══════ LIBRARY TAB ═══════
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            visible: gamesPage.activeTab === 0

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Row {
                    spacing: 8
                    Canvas {
                        width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.fillStyle = "#f59e0b"
                            ctx.fillRect(1, 1, 6, 6); ctx.fillRect(9, 1, 6, 6)
                            ctx.fillRect(1, 9, 6, 6); ctx.fillRect(9, 9, 6, 6)
                        }
                        Component.onCompleted: requestPaint()
                    }
                    Text { text: "Library"; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                    Rectangle {
                        width: 24; height: 20; radius: 4; color: "#1a1500"; border.color: "#3d2f00"; border.width: 1
                        Text { anchors.centerIn: parent; text: gameListModel.count; color: "#f59e0b"; font.pixelSize: 10; font.weight: Font.Bold }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Flow {
                Layout.fillWidth: true; spacing: 14
                Repeater {
                    model: gameListModel
                    delegate: Rectangle {
                        id: gameCard
                        width: (mainCol.width - 70) / 6; height: width * 1.35
                        radius: 8; color: "#0c1120"; border.color: gcHover.containsMouse ? "#f59e0b" : "#141a2a"; border.width: 1; clip: true
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            anchors.fill: parent; anchors.bottomMargin: 44; radius: 8
                            color: model.coverImage !== "" ? "transparent" : Qt.darker(model.color, 2.5); clip: true
                            Image {
                                anchors.fill: parent; source: model.coverImage
                                visible: model.coverImage !== ""; fillMode: Image.PreserveAspectCrop
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 8; visible: model.coverImage === ""
                                Canvas {
                                    Layout.alignment: Qt.AlignHCenter; width: 36; height: 36
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.3); ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        ctx.beginPath()
                                        ctx.moveTo(4, 14); ctx.quadraticCurveTo(4, 9, 10, 9)
                                        ctx.lineTo(13, 9); ctx.lineTo(13, 6); ctx.lineTo(23, 6); ctx.lineTo(23, 9); ctx.lineTo(26, 9)
                                        ctx.quadraticCurveTo(32, 9, 32, 14); ctx.lineTo(32, 22)
                                        ctx.quadraticCurveTo(32, 29, 27, 30); ctx.lineTo(26, 26); ctx.lineTo(10, 26); ctx.lineTo(9, 30)
                                        ctx.quadraticCurveTo(4, 29, 4, 22); ctx.closePath(); ctx.stroke()
                                    }
                                    Component.onCompleted: requestPaint()
                                }
                            }

                            Rectangle {
                                anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.6)
                                visible: gcHover.containsMouse; radius: 8
                                Canvas {
                                    anchors.centerIn: parent; width: 24; height: 24
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = "#fff"; ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        ctx.beginPath(); ctx.roundedRect(2, 6, 20, 14, 3, 3); ctx.stroke()
                                        ctx.beginPath(); ctx.arc(12, 14, 4, 0, Math.PI * 2); ctx.stroke()
                                        ctx.beginPath(); ctx.moveTo(7, 6); ctx.lineTo(9, 3); ctx.lineTo(15, 3); ctx.lineTo(17, 6); ctx.stroke()
                                    }
                                    Component.onCompleted: requestPaint()
                                }
                            }
                        }

                        // Game info
                        ColumnLayout {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            anchors.margins: 8; spacing: 2
                            Text { text: model.name; color: "#f59e0b"; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            RowLayout {
                                spacing: 6
                                Text { text: model.genre; color: "#4a5568"; font.pixelSize: 9 }
                                Text { text: "·"; color: "#4a5568"; font.pixelSize: 9 }
                                Text { text: model.proCount + " pro profiles"; color: "#4a5568"; font.pixelSize: 9 }
                            }
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
        }

        // ═══════ PRO PROFILES TAB ═══════
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            visible: gamesPage.activeTab === 1

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Professional Player Settings"; color: "#f0f6ff"; font.pixelSize: 16; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: proProfilesModel.count + " profiles"; color: "#5a6a7c"; font.pixelSize: 12 }
            }

            // Profile cards
            Flow {
                Layout.fillWidth: true; spacing: 14

                Repeater {
                    model: proProfilesModel
                    delegate: Rectangle {
                        width: (mainCol.width - 28) / 3; height: 200
                        radius: 14; color: "#0c1120"; border.color: ppHover.containsMouse ? "#f59e0b" : "#141a2a"; border.width: 1; clip: true
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Top accent bar
                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            height: 3; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#f59e0b" }
                                GradientStop { position: 1.0; color: "#fbbf24" }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 10

                            // Player info
                            RowLayout {
                                spacing: 12
                                Rectangle {
                                    width: 40; height: 40; radius: 20; color: "#1a1500"; border.color: "#f59e0b"; border.width: 1
                                    Text { anchors.centerIn: parent; text: model.player.charAt(0).toUpperCase(); color: "#f59e0b"; font.pixelSize: 16; font.weight: Font.Bold }
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text { text: model.player; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                                    RowLayout {
                                        spacing: 6
                                        Text { text: model.team; color: "#f59e0b"; font.pixelSize: 11; font.weight: Font.DemiBold; visible: model.team !== "" }
                                        Text { text: "·"; color: "#4a5568"; font.pixelSize: 11; visible: model.team !== "" }
                                        Text { text: model.game; color: "#5a6a7c"; font.pixelSize: 11 }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

                            // Settings grid
                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 8; rowSpacing: 6
                                ProSetting { label: "DPI"; value: model.dpi }
                                ProSetting { label: "Sens"; value: model.sens }
                                ProSetting { label: "Hz"; value: model.hz }
                                ProSetting { label: "Res"; value: model.res }
                            }

                            Item { Layout.fillHeight: true }

                            // Apply button
                            Rectangle {
                                Layout.fillWidth: true; height: 32; radius: 6
                                color: "transparent"; border.color: "#3d2f00"; border.width: 1
                                Text { anchors.centerIn: parent; text: "Apply Settings"; color: "#f59e0b"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                            }
                        }

                        MouseArea { id: ppHover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true; onPressed: function(m){m.accepted=false} }
                    }
                }
            }
        }

        // ═══════ GAME SETTINGS TAB ═══════
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            visible: gamesPage.activeTab === 2

            Text { text: "Optimized Game Configurations"; color: "#f0f6ff"; font.pixelSize: 16; font.weight: Font.Bold }
            Text { text: "Select a game to view recommended in-game settings for maximum FPS and visibility"; color: "#5a6a7c"; font.pixelSize: 12 }

            Flow {
                Layout.fillWidth: true; spacing: 14

                GameSettingCard {
                    width: (mainCol.width - 14) / 2
                    gameName: "Counter-Strike 2"
                    gameColor: "#f59e0b"
                    settings: [
                        {label: "Resolution", value: "1280×960 (Stretched)", rec: true},
                        {label: "Ratio", value: "4:3", rec: true},
                        {label: "Global Shadow Quality", value: "Low", rec: true},
                        {label: "Model/Texture Detail", value: "Low", rec: false},
                        {label: "Shader Detail", value: "Low", rec: true},
                        {label: "Multicore Rendering", value: "Enabled", rec: true},
                        {label: "MSAA", value: "None", rec: true},
                        {label: "FXAA", value: "Disabled", rec: true}
                    ]
                }

                GameSettingCard {
                    width: (mainCol.width - 14) / 2
                    gameName: "Valorant"
                    gameColor: "#ef4444"
                    settings: [
                        {label: "Material Quality", value: "Low", rec: true},
                        {label: "Texture Quality", value: "Low", rec: true},
                        {label: "Detail Quality", value: "Low", rec: true},
                        {label: "UI Quality", value: "Low", rec: false},
                        {label: "Vignette", value: "Off", rec: true},
                        {label: "Anti-Aliasing", value: "None", rec: true},
                        {label: "Anisotropic Filtering", value: "1x", rec: true},
                        {label: "Bloom", value: "Off", rec: true}
                    ]
                }

                GameSettingCard {
                    width: (mainCol.width - 14) / 2
                    gameName: "Fortnite"
                    gameColor: "#06b6d4"
                    settings: [
                        {label: "Rendering Mode", value: "Performance", rec: true},
                        {label: "View Distance", value: "Far", rec: false},
                        {label: "Shadows", value: "Off", rec: true},
                        {label: "Anti-Aliasing", value: "Off", rec: true},
                        {label: "Textures", value: "Low", rec: true},
                        {label: "Effects", value: "Low", rec: true},
                        {label: "Post Processing", value: "Low", rec: true}
                    ]
                }

                GameSettingCard {
                    width: (mainCol.width - 14) / 2
                    gameName: "Apex Legends"
                    gameColor: "#dc2626"
                    settings: [
                        {label: "Texture Streaming", value: "Low", rec: true},
                        {label: "Texture Filtering", value: "Bilinear", rec: true},
                        {label: "Ambient Occlusion", value: "Disabled", rec: true},
                        {label: "Sun Shadow Coverage", value: "Low", rec: true},
                        {label: "Spot Shadow Detail", value: "Disabled", rec: true},
                        {label: "Model Detail", value: "Low", rec: true},
                        {label: "Anti-Aliasing", value: "None", rec: true}
                    ]
                }
            }
        }

        Item { height: 20 }
    }

    // ── Components ──

    component ProSetting: ColumnLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true; spacing: 2
        Text { text: label; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.Bold }
        Text { text: value; color: "#c5d0de"; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
    }

    component GameSettingCard: Rectangle {
        property string gameName: ""
        property color gameColor: "#06b6d4"
        property var settings: []

        implicitHeight: gsInner.implicitHeight + 32
        radius: 14; color: "#0c1120"; border.color: "#141a2a"; border.width: 1; clip: true

        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 3; radius: 14; color: gameColor
        }

        ColumnLayout {
            id: gsInner
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 16; spacing: 10

            RowLayout {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 8; color: Qt.darker(gameColor, 3)
                    border.color: gameColor; border.width: 1
                    Canvas {
                        anchors.centerIn: parent; width: 16; height: 16
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = gameColor; ctx.lineWidth = 1.4; ctx.lineCap = "round"; ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(2, 6); ctx.quadraticCurveTo(2, 3, 5, 3)
                            ctx.lineTo(6, 3); ctx.lineTo(6, 2); ctx.lineTo(10, 2); ctx.lineTo(10, 3); ctx.lineTo(11, 3)
                            ctx.quadraticCurveTo(14, 3, 14, 6); ctx.lineTo(14, 10)
                            ctx.quadraticCurveTo(14, 14, 12, 14); ctx.lineTo(11, 12); ctx.lineTo(5, 12); ctx.lineTo(4, 14)
                            ctx.quadraticCurveTo(2, 14, 2, 10); ctx.closePath(); ctx.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Text { text: gameName; color: "#f0f6ff"; font.pixelSize: 14; font.weight: Font.Bold }
                    Text { text: "Recommended settings for max FPS"; color: "#5a6a7c"; font.pixelSize: 11 }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#141a2a" }

            Repeater {
                model: settings.length
                delegate: Rectangle {
                    Layout.fillWidth: true; implicitHeight: 32; color: "transparent"
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0d1220"; visible: index < settings.length - 1 }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                        Text { text: settings[index].label; color: "#7b8ba3"; font.pixelSize: 12; Layout.fillWidth: true }
                        Text { text: settings[index].value; color: settings[index].rec ? "#22c55e" : "#c5d0de"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Canvas {
                            width: 14; height: 14; visible: settings[index].rec
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.strokeStyle = "#22c55e"; ctx.lineWidth = 2; ctx.lineCap = "round"
                                ctx.beginPath(); ctx.moveTo(3, 7); ctx.lineTo(5.5, 10); ctx.lineTo(11, 4); ctx.stroke()
                            }
                            Component.onCompleted: requestPaint()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 34; radius: 8; Layout.topMargin: 4
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.darker(gameColor, 1.5) }
                    GradientStop { position: 1.0; color: gameColor }
                }
                Text { anchors.centerIn: parent; text: "Apply All Settings"; color: "#fff"; font.pixelSize: 12; font.weight: Font.Bold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
