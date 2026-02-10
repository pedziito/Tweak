import QtQuick 2.15
import QtQuick.Layouts 1.15

/// Compact stat tile with small gauge, used in dashboard 2x2 grid
Rectangle {
    id: card
    radius: 12
    color: "#12172b"
    border.color: "#1c2333"; border.width: 1

    property string cardTitle: ""
    property real value: 0
    property string subtitle: ""
    property color accentStart: "#06b6d4"
    property color accentEnd: "#22d3ee"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Mini gauge
        CircularGauge {
            width: 52; height: 52
            value: card.value
            lineWidth: 5
            startColor: card.accentStart
            endColor: card.accentEnd
            glowColor: card.accentStart
            label: ""
            showText: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: card.cardTitle
                color: "#7b8ba3"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                text: Math.round(card.value) + "%"
                color: "#f0f6ff"
                font.pixelSize: 20
                font.weight: Font.Bold
            }

            Text {
                text: card.subtitle
                color: "#3d4a5c"
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
