import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: perfRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 0
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Performance Benchmark"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: "#f0eaff"
                }
                Text {
                    text: appController.benchmarkHasBaseline
                          ? "Compare system responsiveness before and after applying tweaks."
                          : "Run a baseline benchmark, apply tweaks, then benchmark again to see improvements."
                    color: "#6b5b95"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Legend
            Row {
                spacing: 16
                visible: appController.benchmarkHasBaseline

                Row {
                    spacing: 4
                    Rectangle { width: 12; height: 12; radius: 3; color: "#3b2960"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Before"; color: "#8b7db0"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 4
                    Rectangle {
                        width: 12; height: 12; radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#7c3aed" }
                            GradientStop { position: 1; color: "#d946ef" }
                        }
                    }
                    Text { text: "After"; color: "#8b7db0"; font.pixelSize: 11 }
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            PerfButton {
                text: appController.benchmarkRunning ? "\u25CC Running..." : "\u25C6 Run Baseline"
                enabled: !appController.benchmarkRunning
                accent: "#7c3aed"
                onClicked: appController.runBaseline()
            }
            PerfButton {
                text: appController.benchmarkRunning ? "\u25CC Running..." : "\u25B2 After Tweaks"
                enabled: !appController.benchmarkRunning && appController.benchmarkHasBaseline
                accent: "#10b981"
                onClicked: appController.runAfterTweaks()
            }
            PerfButton {
                text: "\u21BA Reset"
                visible: appController.benchmarkHasBaseline
                accent: "#ef4444"
                onClicked: appController.resetBenchmark()
            }
        }

        // Spinner while running
        Text {
            visible: appController.benchmarkRunning
            text: "Running benchmarks — this takes about 15-30 seconds..."
            color: "#7c3aed"
            font.pixelSize: 12
            font.italic: true

            SequentialAnimation on opacity {
                running: appController.benchmarkRunning
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
            }
        }

        // Bar chart area
        ListView {
            id: benchList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appController.benchmarkResults
            spacing: 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: appController.benchmarkResults.length > 0

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#7c3aed"; opacity: 0.5 }
                background: Rectangle { color: "transparent" }
            }

            delegate: Rectangle {
                width: benchList.width
                height: 90
                radius: 12
                color: "#1a1230"
                border.color: "#2a1f50"

                property var item: modelData
                property double maxVal: {
                    var b = item.baseline || 0
                    var c = item.current || 0
                    return Math.max(b, c, 1)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    // Label row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: item.name
                            color: "#f0eaff"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        // Improvement badge
                        Rectangle {
                            visible: item.baseline > 0 && item.current > 0
                            radius: 8
                            color: {
                                var imp = item.improvement || 0
                                return imp > 0 ? "#152d1a" : imp < 0 ? "#2d1515" : "#1a1230"
                            }
                            implicitWidth: impText.implicitWidth + 16
                            implicitHeight: 22

                            Text {
                                id: impText
                                anchors.centerIn: parent
                                text: {
                                    var imp = item.improvement || 0
                                    var prefix = imp > 0 ? "+" : ""
                                    return prefix + imp.toFixed(1) + "%"
                                }
                                color: {
                                    var imp = item.improvement || 0
                                    return imp > 0 ? "#10b981" : imp < 0 ? "#ef4444" : "#8b7db0"
                                }
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Baseline bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: item.baseline > 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 16
                            radius: 4
                            color: "#15102a"

                            Rectangle {
                                width: parent.width * Math.min(item.baseline / maxVal, 1.0)
                                height: parent.height
                                radius: 4
                                color: "#3b2960"

                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            text: item.baseline.toFixed(1) + " " + item.unit
                            color: "#6b5b95"
                            font.pixelSize: 10
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // After bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: item.current > 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 16
                            radius: 4
                            color: "#15102a"

                            Rectangle {
                                width: parent.width * Math.min(item.current / maxVal, 1.0)
                                height: parent.height
                                radius: 4

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#7c3aed" }
                                    GradientStop { position: 1.0; color: "#d946ef" }
                                }

                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            text: item.current.toFixed(1) + " " + item.unit
                            color: "#d4b8ff"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: appController.benchmarkResults.length === 0 && !appController.benchmarkRunning

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u25C6"
                    font.pixelSize: 48
                    color: "#7c3aed"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No benchmark data yet"
                    color: "#6b5b95"
                    font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Click 'Run Baseline' to start measuring"
                    color: "#4a3d70"
                    font.pixelSize: 12
                }
            }
        }

        // Summary row
        Rectangle {
            Layout.fillWidth: true
            visible: appController.benchmarkResults.length > 0 && appController.benchmarkHasBaseline
            height: 44
            radius: 12
            color: "#1a1230"
            border.color: "#2a1f50"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16

                Text {
                    text: {
                        var results = appController.benchmarkResults
                        var totalImp = 0
                        var count = 0
                        for (var i = 0; i < results.length; i++) {
                            if (results[i].baseline > 0 && results[i].current > 0) {
                                totalImp += results[i].improvement
                                count++
                            }
                        }
                        if (count === 0) return "Awaiting after-tweaks benchmark..."
                        var avg = totalImp / count
                        var prefix = avg > 0 ? "+" : ""
                        return "Overall: " + prefix + avg.toFixed(1) + "% average improvement across " + count + " metrics"
                    }
                    color: "#d4b8ff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }
        }
    }

    component PerfButton: Rectangle {
        property string text: ""
        property color accent: "#7c3aed"
        property bool enabled: true
        signal clicked()

        width: perfBtnText.implicitWidth + 28
        height: 36
        radius: 10
        color: !enabled ? "#15102a" : perfBtnHover.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.15) : "#15102a"
        border.color: !enabled ? "#1e1540" : Qt.rgba(accent.r, accent.g, accent.b, 0.4)
        border.width: 1
        opacity: enabled ? 1.0 : 0.5

        Text {
            id: perfBtnText
            anchors.centerIn: parent
            text: parent.text
            color: parent.enabled ? "#d4b8ff" : "#4a3d70"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: perfBtnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (parent.enabled) parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
