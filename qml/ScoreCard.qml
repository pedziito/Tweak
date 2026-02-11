import QtQuick 2.15
import QtQuick.Layouts 1.15

/// Score overview card — kept as standalone for potential reuse
Rectangle {
    id: scoreCard
    implicitHeight: 200
    radius: 16
    color: "#0c1120"
    border.color: "#141a2a"; border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text { text: "System Score"; color: "#7b8ba3"; font.pixelSize: 14; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: tierL.width + 14; height: 24; radius: 6
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#06b6d4" }
                    GradientStop { position: 1.0; color: "#0ea5e9" }
                }
                Text { id: tierL; anchors.centerIn: parent; text: appController.hwScorer ? appController.hwScorer.tier : "—"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Bold }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                CircularGauge {
                    Layout.alignment: Qt.AlignHCenter
                    width: 80; height: 80
                    value: appController.hwScorer ? appController.hwScorer.gamingScore : 0
                    startColor: "#06b6d4"; endColor: "#22d3ee"; glowColor: "#06b6d4"; label: ""
                }
                Text { Layout.alignment: Qt.AlignHCenter; text: "Gaming"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.DemiBold }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                CircularGauge {
                    Layout.alignment: Qt.AlignHCenter
                    width: 80; height: 80
                    value: appController.hwScorer ? appController.hwScorer.performanceScore : 0
                    startColor: "#f59e0b"; endColor: "#fbbf24"; glowColor: "#f59e0b"; label: ""
                }
                Text { Layout.alignment: Qt.AlignHCenter; text: "Performance"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.DemiBold }
            }
        }
    }
}
