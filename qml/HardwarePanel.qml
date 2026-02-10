import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    Layout.fillWidth: true
    implicitHeight: hwCol.implicitHeight + 36
    radius: 16
    color: "#0f1a2e"
    border.color: "#1e3a5f"

    ColumnLayout {
        id: hwCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: "System Overview"
            font.pixelSize: 16
            font.weight: Font.Bold
            color: "#e2e8f0"
        }

        Grid {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            // CPU
            Text { text: "CPU";         color: "#64748b"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.cpuName || "—"; color: "#cbd5e1"; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true }

            Text { text: "Cores / Threads"; color: "#64748b"; font.pixelSize: 11 }
            Text { text: appController.cpuCores + " / " + appController.cpuThreads; color: "#cbd5e1"; font.pixelSize: 12 }

            // GPU
            Text { text: "GPU";         color: "#64748b"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.gpuName || "—"; color: "#cbd5e1"; font.pixelSize: 12; wrapMode: Text.Wrap }

            Text { text: "GPU Vendor";  color: "#64748b"; font.pixelSize: 11 }
            Text {
                text: appController.gpuVendor || "—"
                color: appController.gpuVendor === "NVIDIA" ? "#76b900"
                     : appController.gpuVendor === "AMD"    ? "#ed1c24"
                     : "#cbd5e1"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            // RAM
            Text { text: "RAM";         color: "#64748b"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.ramText; color: "#cbd5e1"; font.pixelSize: 12 }

            // Motherboard
            Text { text: "Motherboard"; color: "#64748b"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.motherboardName || "—"; color: "#cbd5e1"; font.pixelSize: 12; wrapMode: Text.Wrap }

            // Storage
            Text { text: "Storage";     color: "#64748b"; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { text: appController.storageText; color: "#cbd5e1"; font.pixelSize: 12; wrapMode: Text.Wrap }

            Text { text: "SSD / NVMe";  color: "#64748b"; font.pixelSize: 11 }
            Row {
                spacing: 8
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: appController.hasSsd ? "#10b981" : "#1e3a5f"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text { text: "SSD"; color: "#cbd5e1"; font.pixelSize: 11 }
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: appController.hasNvme ? "#3b82f6" : "#1e3a5f"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text { text: "NVMe"; color: "#cbd5e1"; font.pixelSize: 11 }
            }
        }
    }
}
