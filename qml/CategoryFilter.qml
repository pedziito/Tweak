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
            color: filterRoot.currentCategory === modelData ? "#1e1540" : catBtnHover.containsMouse ? "#16112e" : "#15102a"
            border.color: filterRoot.currentCategory === modelData ? "#7c3aed" : "#2a1f50"
            border.width: 1

            Text {
                id: catBtnText
                anchors.centerIn: parent
                text: modelData
                color: filterRoot.currentCategory === modelData ? "#d4b8ff" : "#8b7db0"
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
