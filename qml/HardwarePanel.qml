import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    Layout.fillWidth: true
    implicitHeight: hwCol.implicitHeight + 36
    radius: 16
    color: "#111821"
    border.color: "#1c2735"

    ColumnLayout {
        id: hwCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: "System Overview"
            font.pixelSize: 16
            font.weight: Font.Bold
            color: "#e6edf6"
        }

        Grid {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            // CPU
            Text { text: "CPU";         color: "#5e7a93"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.cpuName || "—"; color: "#c8d6e2"; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true }

            Text { text: "Cores / Threads"; color: "#5e7a93"; font.pixelSize: 11 }
            Text { text: appController.cpuCores + " / " + appController.cpuThreads; color: "#c8d6e2"; font.pixelSize: 12 }

            // GPU
            Text { text: "GPU";         color: "#5e7a93"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.gpuName || "—"; color: "#c8d6e2"; font.pixelSize: 12; wrapMode: Text.Wrap }

            Text { text: "GPU Vendor";  color: "#5e7a93"; font.pixelSize: 11 }
            Text {
                text: appController.gpuVendor || "—"
                color: appController.gpuVendor === "NVIDIA" ? "#76b900"
                     : appController.gpuVendor === "AMD"    ? "#ed1c24"
                     : "#c8d6e2"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            // RAM
            Text { text: "RAM";         color: "#5e7a93"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.ramText; color: "#c8d6e2"; font.pixelSize: 12 }

            // Motherboard
            Text { text: "Motherboard"; color: "#5e7a93"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.motherboardName || "—"; color: "#c8d6e2"; font.pixelSize: 12; wrapMode: Text.Wrap }

            // Storage
            Text { text: "Storage";     color: "#5e7a93"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.storageText; color: "#c8d6e2"; font.pixelSize: 12; wrapMode: Text.Wrap }

            Text { text: "SSD / NVMe";  color: "#5e7a93"; font.pixelSize: 11 }
            Row {
                spacing: 8
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: appController.hasSsd ? "#5ee87d" : "#3b4a5a"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text { text: "SSD"; color: "#c8d6e2"; font.pixelSize: 11 }
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: appController.hasNvme ? "#5ad6ff" : "#3b4a5a"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text { text: "NVMe"; color: "#c8d6e2"; font.pixelSize: 11 }
            }
        }
    }
}
