import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/// Horizontal tweak card with status dots, compact design
Rectangle {
    id: card
    implicitHeight: cardRow.implicitHeight + 20
    radius: 12
    color: cardHover.containsMouse ? "#151b30" : "#12172b"
    border.color: tweakApplied ? (tweakVerified ? "#166534" : "#164e63")
                               : cardHover.containsMouse ? "#1c2333" : "#161d2e"
    border.width: 1

    property string tweakName: ""
    property string tweakDesc: ""
    property string tweakCategory: ""
    property bool tweakEnabled: true
    property bool tweakApplied: false
    property bool tweakRecommended: false
    property bool tweakVerified: false
    property string tweakRisk: "safe"
    property string tweakLearnMore: ""
    property bool showLearnMore: false
    signal toggled(bool checked)

    Behavior on border.color { ColorAnimation { duration: 180 } }
    Behavior on color { ColorAnimation { duration: 180 } }

    MouseArea {
        id: cardHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }

    ColumnLayout {
        id: cardRow
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        // ── Main row: icon + info + badges + switch ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Status indicator dot
            Rectangle {
                width: 8; height: 8; radius: 4
                Layout.alignment: Qt.AlignVCenter
                color: card.tweakApplied ? (card.tweakVerified ? "#22c55e" : "#06b6d4")
                     : card.tweakRecommended ? "#f59e0b"
                     : "#1c2333"

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Name + description column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: card.tweakName
                    color: card.tweakApplied ? "#e0f7ff" : "#c5d0de"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    text: card.tweakDesc
                    color: "#4a5568"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    lineHeight: 1.3
                }
            }

            // Badges row
            Row {
                spacing: 5

                // Verified
                Rectangle {
                    visible: card.tweakApplied && card.tweakVerified
                    width: verText.width + 12; height: 22; radius: 5
                    color: "#0d2818"
                    border.color: "#166534"; border.width: 1
                    Text { id: verText; anchors.centerIn: parent; text: "\u2713 OK"; color: "#22c55e"; font.pixelSize: 9; font.weight: Font.Bold }
                }

                // Applied (unverified)
                Rectangle {
                    visible: card.tweakApplied && !card.tweakVerified
                    width: appText.width + 12; height: 22; radius: 5
                    color: "#0e2a3d"
                    border.color: "#164e63"; border.width: 1
                    Text { id: appText; anchors.centerIn: parent; text: "\u25CF On"; color: "#22d3ee"; font.pixelSize: 9; font.weight: Font.Bold }
                }

                // Recommended
                Rectangle {
                    visible: card.tweakRecommended && !card.tweakApplied
                    width: recText.width + 12; height: 22; radius: 5
                    color: "#1c1917"
                    border.color: "#854d0e"; border.width: 1
                    Text { id: recText; anchors.centerIn: parent; text: "\u2605 Rec"; color: "#fbbf24"; font.pixelSize: 9; font.weight: Font.Bold }
                }

                // Category
                Rectangle {
                    visible: card.tweakCategory !== ""
                    width: catText2.width + 12; height: 22; radius: 5
                    color: "#0f1423"
                    Text { id: catText2; anchors.centerIn: parent; text: card.tweakCategory; color: "#4a5568"; font.pixelSize: 9; font.weight: Font.DemiBold }
                }

                // Risk badge
                Rectangle {
                    visible: card.tweakRisk === "advanced"
                    width: riskText.width + 12; height: 22; radius: 5
                    color: "#451a03"
                    border.color: "#92400e"; border.width: 1
                    Text { id: riskText; anchors.centerIn: parent; text: "\u26A0 Adv"; color: "#fbbf24"; font.pixelSize: 9; font.weight: Font.Bold }
                }
            }

            // Toggle switch
            Switch {
                id: tweakSwitch
                checked: card.tweakApplied
                Layout.alignment: Qt.AlignVCenter

                indicator: Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    x: tweakSwitch.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 10
                    color: tweakSwitch.checked ? "#0e2a3d" : "#1a1f30"
                    border.color: tweakSwitch.checked ? "#06b6d4" : "#2d3748"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        x: tweakSwitch.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: tweakSwitch.checked ? "#22d3ee" : "#4a5568"

                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }

                onToggled: card.toggled(checked)
            }
        }

        // ── Learn More Expandable ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            spacing: 4
            visible: card.tweakLearnMore !== ""

            Text {
                text: card.showLearnMore ? "\u25BE Hide details" : "\u25B8 Learn more"
                color: "#06b6d4"
                font.pixelSize: 10
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.showLearnMore = !card.showLearnMore
                }
            }

            Rectangle {
                visible: card.showLearnMore
                Layout.fillWidth: true
                implicitHeight: lmText.implicitHeight + 14
                radius: 8
                color: "#0b0f19"
                border.color: "#1c2333"; border.width: 1

                Text {
                    id: lmText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: card.tweakLearnMore
                    color: "#7b8ba3"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    lineHeight: 1.4
                }
            }
        }
    }
}
