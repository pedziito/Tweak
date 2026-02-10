import QtQuick 2.15
import QtQuick.Layouts 1.15

/// Hardware info panel — standalone version for potential reuse
Rectangle {
    Layout.fillWidth: true
    implicitHeight: hwCol.implicitHeight + 36
    radius: 16
    color: "#12172b"
    border.color: "#1c2333"; border.width: 1

    ColumnLayout {
        id: hwCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: "System Overview"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#c5d0de"
        }

        Grid {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 14
            rowSpacing: 7

            Text { text: "CPU";         color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: appController.cpuName || "—"; color: "#c5d0de"; font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true }

            Text { text: "Cores/Threads"; color: "#4a5568"; font.pixelSize: 10 }
            Text { text: appController.cpuCores + " / " + appController.cpuThreads; color: "#c5d0de"; font.pixelSize: 11 }

            Text { text: "GPU";         color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: appController.gpuName || "—"; color: "#c5d0de"; font.pixelSize: 11; wrapMode: Text.Wrap }

            Text { text: "GPU Vendor";  color: "#4a5568"; font.pixelSize: 10 }
            Text {
                text: appController.gpuVendor || "—"
                color: appController.gpuVendor === "NVIDIA" ? "#76b900"
                     : appController.gpuVendor === "AMD"    ? "#ed1c24"
                     : "#c5d0de"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text { text: "RAM";         color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: appController.ramText; color: "#c5d0de"; font.pixelSize: 11 }

            Text { text: "Motherboard"; color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: appController.motherboardName || "—"; color: "#c5d0de"; font.pixelSize: 11; wrapMode: Text.Wrap }

            Text { text: "Storage";     color: "#4a5568"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: appController.storageText; color: "#c5d0de"; font.pixelSize: 11; wrapMode: Text.Wrap }

            Text { text: "SSD / NVMe";  color: "#4a5568"; font.pixelSize: 10 }
            Row {
                spacing: 8
                Rectangle { width: 8; height: 8; radius: 4; color: appController.hasSsd ? "#10b981" : "#1c2333"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "SSD"; color: "#c5d0de"; font.pixelSize: 10 }
                Rectangle { width: 8; height: 8; radius: 4; color: appController.hasNvme ? "#06b6d4" : "#1c2333"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "NVMe"; color: "#c5d0de"; font.pixelSize: 10 }
            }
        }
    }
}
