import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Item {
    id: tweaksPage
    signal restartRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Tweaks"
                    color: "#f1f5f9"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }
                Text {
                    text: appController.tweakModel.rowCount() + " tweaks available  \u00B7  " + appController.selectedCategory
                    color: "#64748b"
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Search field
            Rectangle {
                width: 240; height: 38; radius: 10
                color: "#111827"
                border.color: searchField.activeFocus ? "#6366f1" : "#1e293b"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text { text: "\u2315"; font.pixelSize: 15; color: "#475569" }
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
        }

        // ── Stats bar ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Applied stat
            Rectangle {
                implicitWidth: appliedStatRow.width + 24; height: 36; radius: 10
                color: "#0f172a"
                border.color: "#1e293b"
                border.width: 1

                Row {
                    id: appliedStatRow
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle { width: 8; height: 8; radius: 4; color: "#22c55e"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: appController.appliedCount + " Applied"; color: "#94a3b8"; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
            }

            // Recommended stat
            Rectangle {
                implicitWidth: recStatRow.width + 24; height: 36; radius: 10
                color: "#0f172a"
                border.color: "#1e293b"
                border.width: 1

                Row {
                    id: recStatRow
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle { width: 8; height: 8; radius: 4; color: "#6366f1"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: appController.recommendedCount + " Recommended"; color: "#94a3b8"; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
            }

            Item { Layout.fillWidth: true }

            // Verify All button
            Rectangle {
                width: verifyText.width + 28; height: 36; radius: 10
                color: "#052e16"
                border.color: "#166534"
                border.width: 1

                Text {
                    id: verifyText
                    anchors.centerIn: parent
                    text: "\u2713  Verify All"
                    color: "#22c55e"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appController.verifyAllTweaks()
                }
            }

            // Apply Recommended button
            Rectangle {
                width: applyRecText.width + 28; height: 36; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#6366f1" }
                    GradientStop { position: 1.0; color: "#8b5cf6" }
                }

                Text {
                    id: applyRecText
                    anchors.centerIn: parent
                    text: "Apply Recommended"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appController.applyAllGaming()
                }
            }

            // Save button
            Rectangle {
                width: saveBtnText.width + 28; height: 36; radius: 10
                color: "#0f172a"
                border.color: "#22c55e"
                border.width: 1

                Text {
                    id: saveBtnText
                    anchors.centerIn: parent
                    text: "\u2714 Save & Apply"
                    color: "#22c55e"
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

            // Restore button
            Rectangle {
                width: restoreText.width + 28; height: 36; radius: 10
                color: "transparent"
                border.color: "#7f1d1d"
                border.width: 1

                Text {
                    id: restoreText
                    anchors.centerIn: parent
                    text: "Restore All"
                    color: "#f87171"
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
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#6366f1"
                    opacity: 0.4
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
                tweakVerified: model.verified || false
                tweakRisk: model.risk || "safe"
                tweakLearnMore: model.learnMore || ""
                onToggled: appController.toggleTweak(model.index)
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: tweakList.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u2699"
                    font.pixelSize: 40
                    color: "#374151"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No tweaks match your filter"
                    color: "#475569"
                    font.pixelSize: 14
                }
            }
        }
    }
}
