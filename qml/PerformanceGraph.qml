import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: perfRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 16
    color: "#111821"
    border.color: "#1c2735"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "⚡ Performance Benchmark"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: "#e6edf6"
            }

            Item { Layout.fillWidth: true }

            // Legend
            Row {
                spacing: 16
                visible: appController.benchmarkHasBaseline

                Row {
                    spacing: 4
                    Rectangle { width: 12; height: 12; radius: 3; color: "#3b5998"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Before"; color: "#8aa3b8"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 4
                    Rectangle { width: 12; height: 12; radius: 3; color: "#5ad6ff"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "After"; color: "#8aa3b8"; font.pixelSize: 11 }
                }
            }
        }

        // Description
        Text {
            text: appController.benchmarkHasBaseline
                  ? "Compare system responsiveness before and after applying tweaks."
                  : "Run a baseline benchmark, apply tweaks, then benchmark again to see improvements."
            color: "#5e7a93"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: appController.benchmarkRunning ? "⏳ Running..." : "📊 Run Baseline"
                enabled: !appController.benchmarkRunning
                Material.background: "#1a3a50"
                Material.foreground: "#5ad6ff"
                font.weight: Font.DemiBold
                font.pixelSize: 12
                onClicked: appController.runBaseline()
            }
            Button {
                text: appController.benchmarkRunning ? "⏳ Running..." : "📈 Benchmark After Tweaks"
                enabled: !appController.benchmarkRunning && appController.benchmarkHasBaseline
                Material.background: appController.benchmarkHasBaseline ? "#1a4a30" : "#1a2230"
                Material.foreground: appController.benchmarkHasBaseline ? "#5ee87d" : "#5e7a93"
                font.weight: Font.DemiBold
                font.pixelSize: 12
                onClicked: appController.runAfterTweaks()
            }
            Button {
                text: "↺ Reset"
                visible: appController.benchmarkHasBaseline
                flat: true
                font.pixelSize: 11
                Material.foreground: "#5e7a93"
                onClicked: appController.resetBenchmark()
            }
        }

        // Spinner while running
        Text {
            visible: appController.benchmarkRunning
            text: "Running benchmarks — this takes about 15-30 seconds..."
            color: "#5ad6ff"
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

            delegate: Item {
                width: benchList.width
                height: 80

                property var item: modelData
                property double maxVal: {
                    var b = item.baseline || 0
                    var c = item.current || 0
                    return Math.max(b, c, 1)
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    // Label row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: item.name
                            color: "#c8d6e2"
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
                                return imp > 0 ? "#1a3d1f" : imp < 0 ? "#3d1a1a" : "#1a2230"
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
                                    return imp > 0 ? "#5ee87d" : imp < 0 ? "#ff6b6b" : "#8aa3b8"
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
                            color: "#0d1219"

                            Rectangle {
                                width: parent.width * Math.min(item.baseline / maxVal, 1.0)
                                height: parent.height
                                radius: 4
                                color: "#3b5998"

                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            text: item.baseline.toFixed(1) + " " + item.unit
                            color: "#6b8299"
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
                            color: "#0d1219"

                            Rectangle {
                                width: parent.width * Math.min(item.current / maxVal, 1.0)
                                height: parent.height
                                radius: 4

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#2a7a9c" }
                                    GradientStop { position: 1.0; color: "#5ad6ff" }
                                }

                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            text: item.current.toFixed(1) + " " + item.unit
                            color: "#5ad6ff"
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
                    text: "📊"
                    font.pixelSize: 48
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No benchmark data yet"
                    color: "#5e7a93"
                    font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Click 'Run Baseline' to start measuring"
                    color: "#3b4a5a"
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
            color: "#0d1219"
            border.color: "#1c2735"

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
                    color: "#8aa3b8"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }
        }
    }
}
