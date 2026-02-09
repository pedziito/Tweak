import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Row {
    id: filterRoot
    spacing: 6

    property string currentCategory: appController.selectedCategory

    Repeater {
        model: appController.categories

        delegate: Button {
            text: modelData
            flat: true
            font.pixelSize: 11
            font.weight: filterRoot.currentCategory === modelData ? Font.Bold : Font.Normal

            Material.foreground: filterRoot.currentCategory === modelData ? "#5ad6ff" : "#5e7a93"

            background: Rectangle {
                radius: 10
                color: filterRoot.currentCategory === modelData ? "#1a3a50" : "#111821"
                border.color: filterRoot.currentCategory === modelData ? "#2a7a9c" : "#1c2735"
            }

            onClicked: {
                filterRoot.currentCategory = modelData
                appController.selectedCategory = modelData
            }
        }
    }
}
