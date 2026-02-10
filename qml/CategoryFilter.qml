import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Flow {
    id: filterRoot
    spacing: 6

    property string currentCategory: appController.selectedCategory

    Repeater {
        model: appController.categories

        delegate: Rectangle {
            width: catBtnText.implicitWidth + 24
            height: 32
            radius: 10
            color: filterRoot.currentCategory === modelData ? "#0f2340" : catBtnHover.containsMouse ? "#0d1b30" : "#0c1524"
            border.color: filterRoot.currentCategory === modelData ? "#3b82f6" : "#1e3a5f"
            border.width: 1

            Text {
                id: catBtnText
                anchors.centerIn: parent
                text: modelData
                color: filterRoot.currentCategory === modelData ? "#93c5fd" : "#94a3b8"
                font.pixelSize: 11
                font.weight: filterRoot.currentCategory === modelData ? Font.Bold : Font.Normal
            }

            MouseArea {
                id: catBtnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    filterRoot.currentCategory = modelData
                    appController.selectedCategory = modelData
                }
            }

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
    }
}
