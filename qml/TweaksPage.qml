import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Item {
    id: tweaksPage
    signal restartRequested()

    property string activeTab: "General"
    property string activeSubCat: "All"

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ═══════ TOP TABS (Basic / General / Advanced / Saved) ═══════
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 46; color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141a2a" }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 28; anchors.rightMargin: 28; spacing: 0

                Row {
                    spacing: 0
                    Repeater {
                        model: ["Basic", "General", "Advanced", "Saved"]
                        delegate: Rectangle {
                            width: tabLabel.implicitWidth + 32; height: 44; color: "transparent"
                            property bool isActive: tweaksPage.activeTab === modelData
                            Text {
                                id: tabLabel; anchors.centerIn: parent
                                text: modelData
                                color: isActive ? "#f59e0b" : tabMouse.containsMouse ? "#c5d0de" : "#5a6a7c"
                                font.pixelSize: 13; font.weight: isActive ? Font.Bold : Font.Normal
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 12; height: 2; radius: 1; color: "#f59e0b"; visible: isActive
                            }
                            MouseArea {
                                id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { tweaksPage.activeTab = modelData; tweaksPage.activeSubCat = "All" }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Search + menu icons
                Row {
                    spacing: 12; anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 240; height: 34; radius: 8
                        color: "#0c1120"; border.color: searchField.activeFocus ? "#06b6d4" : "#141a2a"; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 6
                            Canvas {
                                width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = "#4a5568"; ctx.lineWidth = 1.5; ctx.lineCap = "round"
                                    ctx.beginPath(); ctx.arc(6, 6, 5, 0, Math.PI * 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(10, 10); ctx.lineTo(13, 13); ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                            }
                            TextInput {
                                id: searchField; Layout.fillWidth: true
                                color: "#e0f7ff"; font.pixelSize: 12; clip: true
                                Text {
                                    anchors.fill: parent; text: "Search optimizations..."
                                    color: "#3d4a5c"; font.pixelSize: 12; visible: !searchField.text && !searchField.activeFocus
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onTextChanged: appController.filterText = text
                            }
                        }
                    }
                }
            }
        }

        // ═══════ SUB-CATEGORY FILTERS ═══════
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 42; color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#0f1520" }

            Row {
                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 28
                spacing: 0
                Repeater {
                    model: {
                        var cats = ["All"]
                        if (appController.categories) {
                            for (var i = 0; i < appController.categories.length; i++) {
                                if (appController.categories[i] !== "All") cats.push(appController.categories[i])
                            }
                        }
                        return cats
                    }
                    delegate: Rectangle {
                        width: scLabel.implicitWidth + 24; height: 32; color: "transparent"
                        property bool isActive: tweaksPage.activeSubCat === modelData
                        Text {
                            id: scLabel; anchors.centerIn: parent; text: modelData
                            color: isActive ? "#f59e0b" : scMouse.containsMouse ? "#c5d0de" : "#5a6a7c"
                            font.pixelSize: 12; font.weight: isActive ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: scMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tweaksPage.activeSubCat = modelData
                                appController.selectedCategory = modelData === "All" ? "All" : modelData
                            }
                        }
                    }
                }
            }
        }

        // ═══════ APPLY ALL VISIBLE BUTTON ═══════
        RowLayout {
            Layout.fillWidth: true; Layout.leftMargin: 28; Layout.rightMargin: 28; spacing: 12

            Rectangle {
                width: applyAllLabel.width + 32; height: 38; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#06b6d4" }
                    GradientStop { position: 1.0; color: "#0ea5e9" }
                }
                Text { id: applyAllLabel; anchors.centerIn: parent; text: "⚡ Apply All Visible"; color: "#fff"; font.pixelSize: 12; font.weight: Font.Bold }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var rows = []
                        for (var i = 0; i < appController.tweakModel.rowCount(); i++) {
                            var idx = appController.tweakModel.index(i, 0)
                            var applied = appController.tweakModel.data(idx, 262)
                            if (applied) continue
                            var cat = appController.tweakModel.data(idx, 260) || ""
                            var risk = appController.tweakModel.data(idx, 264) || "safe"
                            var status = appController.tweakModel.data(idx, 267) || "stable"
                            var name = appController.tweakModel.data(idx, 258) || ""
                            var desc = appController.tweakModel.data(idx, 259) || ""

                            // Tab filtering
                            var tabOk = true
                            if (tweaksPage.activeTab === "Basic") {
                                var basicCats = ["System", "Privacy", "Visual"]
                                tabOk = basicCats.indexOf(cat) !== -1
                            } else if (tweaksPage.activeTab === "Advanced") {
                                tabOk = (risk === "advanced") || (status === "experimental") || (status === "testing")
                            } else if (tweaksPage.activeTab === "Saved") {
                                tabOk = false // skip; all applied already
                            }
                            if (!tabOk) continue

                            // Sub-category filtering
                            if (tweaksPage.activeSubCat !== "All" && cat !== tweaksPage.activeSubCat) continue

                            // Search filtering
                            var q = searchField.text.toLowerCase()
                            if (q !== "" && name.toLowerCase().indexOf(q) === -1 && desc.toLowerCase().indexOf(q) === -1) continue

                            rows.push(i)
                        }
                        if (rows.length > 0) root.openBatchApply(rows)
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ═══════ 3-COLUMN GRID OF TWEAK CARDS ═══════
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: width; contentHeight: gridFlow.implicitHeight + 40
            clip: true; boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.4 }
                background: Rectangle { color: "transparent" }
            }

            Flow {
                id: gridFlow
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 28
                spacing: 14

                Repeater {
                    model: appController.tweakModel

                    delegate: TweakCard {
                        width: (gridFlow.width - 28) / 3
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

                        visible: {
                            // Tab filtering
                            var tabOk = true
                            if (tweaksPage.activeTab === "Basic") {
                                var basicCats = ["System", "Privacy", "Visual"]
                                tabOk = basicCats.indexOf(model.category) !== -1
                            } else if (tweaksPage.activeTab === "General") {
                                tabOk = true // show all
                            } else if (tweaksPage.activeTab === "Advanced") {
                                tabOk = (model.risk === "advanced") || (model.status === "experimental") || (model.status === "testing")
                            } else if (tweaksPage.activeTab === "Saved") {
                                tabOk = model.applied
                            }
                            if (!tabOk) return false

                            // Sub-category filtering
                            var catOk = (tweaksPage.activeSubCat === "All" || model.category === tweaksPage.activeSubCat)
                            if (!catOk) return false

                            // Search filtering
                            var q = searchField.text.toLowerCase()
                            if (q === "") return true
                            return model.name.toLowerCase().indexOf(q) !== -1 || model.description.toLowerCase().indexOf(q) !== -1
                        }
                        height: visible ? implicitHeight : 0
                        opacity: visible ? 1 : 0
                    }
                }
            }
        }
    }
}
