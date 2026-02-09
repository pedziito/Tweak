import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Dashboard stat card with circular gauge.
Rectangle {
    id: card
    implicitWidth: 200
    implicitHeight: 170
    radius: 18
    color: "#1a1230"
    border.color: "#2a1f50"
    border.width: 1

    property string cardTitle: ""
    property real value: 0
    property string subtitle: ""
    property string overrideText: ""
    property string overrideLabel: ""
    property color accentStart: "#7c3aed"
    property color accentEnd: "#d946ef"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: card.cardTitle
                color: "#8b7db0"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Rectangle {
                width: 6; height: 6; radius: 3
                color: card.accentStart
                opacity: 0.8
            }
        }

        Item { Layout.fillHeight: true }

        CircularGauge {
            Layout.alignment: Qt.AlignHCenter
            width: 80
            height: 80
            value: card.value
            startColor: card.accentStart
            endColor: card.accentEnd
            glowColor: card.accentStart
            label: card.overrideLabel !== "" ? card.overrideLabel : "%"
            showText: true
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: card.subtitle
            color: "#6b5b95"
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }
}
