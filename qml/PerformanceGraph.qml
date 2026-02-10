import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Performance benchmark page with bar chart comparison
Rectangle {
    id: perfRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        // ═══════ HEADER ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 3
                Text {
                    text: "Performance Benchmark"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: "#f0f6ff"
                }
                Text {
                    text: appController.benchmarkHasBaseline
                          ? "Compare responsiveness before and after applying tweaks."
                          : "Run a baseline, apply tweaks, then benchmark again."
                    color: "#4a5568"
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Legend
            Row {
                spacing: 16
                visible: appController.benchmarkHasBaseline

                Row {
                    spacing: 5
                    Rectangle { width: 10; height: 10; radius: 3; color: "#1c2333"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Before"; color: "#4a5568"; font.pixelSize: 10 }
                }
                Row {
                    spacing: 5
                    Rectangle {
                        width: 10; height: 10; radius: 3; anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#06b6d4" }
                            GradientStop { position: 1; color: "#22d3ee" }
                        }
                    }
                    Text { text: "After"; color: "#4a5568"; font.pixelSize: 10 }
                }
            }
        }

        // ═══════ ACTION BUTTONS ═══════
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            PerfButton {
                text: appController.benchmarkRunning ? "\u25CC Running..." : "\u25C6 Run Baseline"
                enabled: !appController.benchmarkRunning
                accent: "#06b6d4"
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
                accent: "#f43f5e"
                onClicked: appController.resetBenchmark()
            }
        }

        // Spinner
        Text {
            visible: appController.benchmarkRunning
            text: "Running benchmarks — 15-30 seconds..."
            color: "#06b6d4"
            font.pixelSize: 11
            font.italic: true

            SequentialAnimation on opacity {
                running: appController.benchmarkRunning
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
            }
        }

        // ═══════ BAR CHART RESULTS ═══════
        ListView {
            id: benchList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appController.benchmarkResults
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: appController.benchmarkResults.length > 0

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#06b6d4"; opacity: 0.4 }
                background: Rectangle { color: "transparent" }
            }

            delegate: Rectangle {
                width: benchList.width
                height: barCol.height + 24
                radius: 12
                color: "#12172b"
                border.color: "#1c2333"; border.width: 1

                ColumnLayout {
                    id: barCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 14
                    spacing: 8

                    // Test name + change
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: modelData.name || ""; color: "#c5d0de"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: (modelData.after || 0) > 0
                            text: {
                                var diff = (modelData.after || 0) - (modelData.before || 0)
                                return (diff >= 0 ? "+" : "") + diff.toFixed(1) + " ms"
                            }
                            color: {
                                var diff = (modelData.after || 0) - (modelData.before || 0)
                                return diff <= 0 ? "#22c55e" : "#f43f5e"
                            }
                            font.pixelSize: 10; font.weight: Font.Bold
                        }
                    }

                    // Before bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "Before"; color: "#3d4a5c"; font.pixelSize: 9; Layout.preferredWidth: 40 }
                        Rectangle {
                            Layout.fillWidth: true; height: 14; radius: 4; color: "#0f1423"
                            Rectangle {
                                width: Math.max(4, parent.width * Math.min((modelData.before || 0) / 200, 1))
                                height: parent.height; radius: 4; color: "#1c2333"
                            }
                        }
                        Text { text: (modelData.before || 0).toFixed(1) + "ms"; color: "#4a5568"; font.pixelSize: 9; Layout.preferredWidth: 50; horizontalAlignment: Text.AlignRight }
                    }

                    // After bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: (modelData.after || 0) > 0
                        Text { text: "After"; color: "#3d4a5c"; font.pixelSize: 9; Layout.preferredWidth: 40 }
                        Rectangle {
                            Layout.fillWidth: true; height: 14; radius: 4; color: "#0f1423"
                            Rectangle {
                                width: Math.max(4, parent.width * Math.min((modelData.after || 0) / 200, 1))
                                height: parent.height; radius: 4
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "#06b6d4" }
                                    GradientStop { position: 1; color: "#22d3ee" }
                                }
                            }
                        }
                        Text { text: (modelData.after || 0).toFixed(1) + "ms"; color: "#22d3ee"; font.pixelSize: 9; Layout.preferredWidth: 50; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }

        // Empty state
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: appController.benchmarkResults.length === 0 && !appController.benchmarkRunning
            spacing: 10

            Item { Layout.fillHeight: true }
            Text { Layout.alignment: Qt.AlignHCenter; text: "\u25B2"; font.pixelSize: 42; color: "#1c2333" }
            Text { Layout.alignment: Qt.AlignHCenter; text: "No benchmark data yet"; color: "#3d4a5c"; font.pixelSize: 14 }
            Text { Layout.alignment: Qt.AlignHCenter; text: "Run a baseline to start"; color: "#2d3748"; font.pixelSize: 11 }
            Item { Layout.fillHeight: true }
        }
    }

    // ── Inline Button Component ──
    component PerfButton: Rectangle {
        property string text: ""
        property color accent: "#06b6d4"
        property bool enabled: true
        signal clicked()

        width: pbText.width + 28; height: 36; radius: 8
        opacity: enabled ? 1.0 : 0.4
        color: pbHover.containsMouse && enabled ? Qt.rgba(accent.r, accent.g, accent.b, 0.12) : "#12172b"
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.35)
        border.width: 1

        Text { id: pbText; anchors.centerIn: parent; text: parent.text; color: parent.accent; font.pixelSize: 11; font.weight: Font.DemiBold }

        MouseArea {
            id: pbHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (parent.enabled) parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
