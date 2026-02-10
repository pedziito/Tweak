import QtQuick 2.15

/// Circular gauge with glow effect, used in stat cards and score display
Canvas {
    id: gauge
    width: 100
    height: 100

    property real value: 0
    property real lineWidth: 7
    property color trackColor: "#1c2333"
    property color startColor: "#06b6d4"
    property color endColor: "#22d3ee"
    property color glowColor: "#06b6d4"
    property bool showText: true
    property string label: ""
    property real animatedValue: 0

    Behavior on animatedValue { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    onValueChanged: animatedValue = value
    onAnimatedValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var cx = width / 2
        var cy = height / 2
        var r = Math.min(cx, cy) - lineWidth / 2 - 4
        var startAngle = -Math.PI / 2
        var fullAngle = 2 * Math.PI
        var endAngle = startAngle + fullAngle * (animatedValue / 100)

        // Track
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, fullAngle)
        ctx.strokeStyle = trackColor
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"
        ctx.stroke()

        // Value arc
        if (animatedValue > 0) {
            var gradient = ctx.createConicalGradient(cx, cy, startAngle)
            gradient.addColorStop(0, startColor)
            gradient.addColorStop(animatedValue / 100, endColor)

            ctx.save()
            ctx.shadowColor = glowColor
            ctx.shadowBlur = 8
            ctx.beginPath()
            ctx.arc(cx, cy, r, startAngle, endAngle)
            ctx.strokeStyle = gradient
            ctx.lineWidth = lineWidth
            ctx.lineCap = "round"
            ctx.stroke()
            ctx.restore()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 1
        visible: showText

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(gauge.animatedValue) + "%"
            font.pixelSize: gauge.width * 0.22
            font.weight: Font.Bold
            color: "#f0f6ff"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: gauge.label !== ""
            text: gauge.label
            font.pixelSize: gauge.width * 0.11
            color: "#4a5568"
        }
    }
}
