import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    Layout.fillWidth: true
    radius: 16
    color: "#0d1117"
    border.color: "#1e293b"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: "Startup Cleanup"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#e2e8f0"
        }

        Text {
            visible: startupList.count === 0
            text: "No startup items detected.\nRun on Windows to scan."
            color: "#64748b"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }

        ListView {
            id: startupList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appController.startupSuggestions
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: startupList.width
                implicitHeight: startupCol.implicitHeight + 14
                radius: 10
                color: "#111827"
                border.color: "#1e293b"

                Column {
                    id: startupCol
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 3

                    Text {
                        text: modelData.name
                        color: "#e2e8f0"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: modelData.source
                        color: "#64748b"
                        font.pixelSize: 10
                    }
                    Text {
                        text: modelData.command
                        color: "#475569"
                        font.pixelSize: 10
                        wrapMode: Text.WrapAnywhere
                        width: parent.width
                    }
                }
            }
        }
    }
}
