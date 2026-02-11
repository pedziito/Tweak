import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Hone-style tweaks page — underline category tabs + clean optimization list
Item {
    id: tweaksPage
    signal restartRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 0

        // ═══════ HEADER BAR ═══════
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 16
            spacing: 16

            ColumnLayout {
                spacing: 3
                Text {
                    text: appController.tweakModel.rowCount() + " Optimizations"
                    color: "#f0f6ff"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                Text {
                    text: appController.appliedCount + " active  \u00B7  " + appController.recommendedCount + " recommended"
                    color: "#4a5568"
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            // Search
            Rectangle {
                width: 240; height: 36; radius: 8
                color: "#0c1120"
                border.color: searchField.activeFocus ? "#06b6d4" : "#141a2a"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 6
                    Text { text: "\u2315"; font.pixelSize: 14; color: "#4a5568" }
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: "#e0f7ff"
                        font.pixelSize: 12
                        clip: true
                        Text {
                            anchors.fill: parent
                            text: "Search tweaks..."
                            color: "#3d4a5c"
                            font.pixelSize: 12
                            visible: !searchField.text && !searchField.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }
                        onTextChanged: appController.filterText = text
                    }
                }
            }

            // Action buttons
            Row {
                spacing: 8

                HeaderBtn { label: "\u2713 Verify All"; accent: "#22c55e"; onClicked: appController.verifyAllTweaks() }
                HeaderBtn {
                    label: "Apply Recommended"
                    accent: "#06b6d4"
                    filled: true
                    onClicked: appController.applyAllGaming()
                }
                HeaderBtn {
                    label: "Save & Apply"
                    accent: "#22c55e"
                    onClicked: {
                        appController.saveConfiguration("current")
                        tweaksPage.restartRequested()
                    }
                }
                HeaderBtn { label: "Restore All"; accent: "#f43f5e"; onClicked: appController.restoreAll() }
            }
        }

        // ═══════ CATEGORY TABS (Hone-style underline) ═══════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: "#141a2a"
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Repeater {
                    model: appController.categories

                    delegate: Rectangle {
                        width: catTabText.implicitWidth + 28
                        height: 38
                        color: "transparent"

                        property bool isActive: appController.selectedCategory === modelData

                        Text {
                            id: catTabText
                            anchors.centerIn: parent
                            text: modelData
                            color: isActive ? "#22d3ee" : catTabMouse.containsMouse ? "#c5d0de" : "#4a5568"
                            font.pixelSize: 12
                            font.weight: isActive ? Font.Bold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 8
                            height: 2; radius: 1
                            color: "#06b6d4"
                            visible: isActive
                        }

                        MouseArea {
                            id: catTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appController.selectedCategory = modelData
                        }
                    }
                }
            }
        }

        // ═══════ TWEAK CARDS LIST ═══════
        ListView {
            id: tweakList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            model: appController.tweakModel
            spacing: 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.4 }
                background: Rectangle { color: "transparent" }
            }

            delegate: TweakCard {
                width: tweakList.width
                tweakName: model.name
                tweakDesc: model.description
                tweakCategory: model.category
                tweakApplied: model.applied
                tweakRecommended: model.recommended
                tweakVerified: model.verified || false
                tweakRisk: model.risk || "safe"
                tweakLearnMore: model.learnMore || ""
                tweakStatus: model.status || "stable"
                onToggled: appController.toggleTweak(model.index)
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: tweakList.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u2699"
                    font.pixelSize: 36
                    color: "#1c2333"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No tweaks match your filter"
                    color: "#3d4a5c"
                    font.pixelSize: 13
                }
            }
        }
    }

    // ── Inline Button Component ──
    component HeaderBtn: Rectangle {
        property string label: ""
        property color accent: "#06b6d4"
        property bool filled: false
        signal clicked()

        width: hbText.width + 24; height: 34; radius: 8
        color: filled ? "transparent" : "transparent"
        border.color: filled ? "transparent" : Qt.rgba(accent.r, accent.g, accent.b, 0.3)
        border.width: filled ? 0 : 1

        gradient: filled ? fillGrad : null
        Gradient {
            id: fillGrad
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#06b6d4" }
            GradientStop { position: 1.0; color: "#0ea5e9" }
        }

        Text {
            id: hbText
            anchors.centerIn: parent
            text: parent.label
            color: parent.filled ? "#ffffff" : parent.accent
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
