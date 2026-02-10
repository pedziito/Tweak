import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Tweaks Page — category filter + tweak cards list
Item {
    id: tweaksPage

    // Signal to trigger restart dialog in Main.qml
    signal restartRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Tweaks"
                    color: "#e2e8f0"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                Text {
                    text: appController.tweakModel.rowCount() + " tweaks available  \u00B7  " + appController.selectedCategory
                    color: "#64748b"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Search field
            Rectangle {
                width: 220; height: 36; radius: 10
                color: "#0c1524"
                border.color: searchField.activeFocus ? "#3b82f6" : "#1e3a5f"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text { text: "\u2315"; font.pixelSize: 15; color: "#64748b" }
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: "#e2e8f0"
                        font.pixelSize: 12
                        clip: true
                        Text {
                            anchors.fill: parent
                            text: "Search tweaks..."
                            color: "#475569"
                            font.pixelSize: 12
                            visible: !searchField.text && !searchField.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }
                        onTextChanged: appController.filterText = text
                    }
                }
            }

            // Save button
            Rectangle {
                width: saveBtnText.width + 28; height: 36; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#10b981" }
                    GradientStop { position: 1.0; color: "#06b6d4" }
                }

                Text {
                    id: saveBtnText
                    anchors.centerIn: parent
                    text: "\u2714  Save"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        appController.saveConfiguration("current")
                        tweaksPage.restartRequested()
                    }
                }
            }

            // Apply All button
            Rectangle {
                width: applyAllText.width + 28; height: 36; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#3b82f6" }
                    GradientStop { position: 1.0; color: "#06b6d4" }
                }

                Text {
                    id: applyAllText
                    anchors.centerIn: parent
                    text: "Apply All"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appController.applyAllGaming()
                }
            }

            // Restore All button
            Rectangle {
                width: restoreAllText.width + 28; height: 36; radius: 10
                color: "transparent"
                border.color: "#ef4444"
                border.width: 1

                Text {
                    id: restoreAllText
                    anchors.centerIn: parent
                    text: "Restore All"
                    color: "#ef4444"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appController.restoreAll()
                }
            }
        }

        // ── Category filter ──
        CategoryFilter {
            Layout.fillWidth: true
        }

        // ── Tweak Cards List ──
        ListView {
            id: tweakList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appController.tweakModel
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#3b82f6"
                    opacity: 0.5
                }
                background: Rectangle { color: "transparent" }
            }

            delegate: TweakCard {
                width: tweakList.width
                tweakName: model.name
                tweakDesc: model.description
                tweakCategory: model.category
                tweakApplied: model.applied
                tweakRecommended: model.recommended
                tweakRisk: model.risk || "safe"
                tweakLearnMore: model.learnMore || ""
                onToggled: appController.toggleTweak(model.index)
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                text: "No tweaks match your filter"
                color: "#475569"
                font.pixelSize: 14
                visible: tweakList.count === 0
            }
        }
    }
}
