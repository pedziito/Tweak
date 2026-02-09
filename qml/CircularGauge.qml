import QtQuick 2.15

/// Circular arc gauge with percentage, gradient stroke, glow effect.
Canvas {
    id: gauge
    width: 100
    height: 100

    property real value: 0          // 0..100
    property real lineWidth: 8
    property color trackColor: "#1e1540"
    property color startColor: "#7c3aed"
    property color endColor: "#d946ef"
    property color glowColor: "#7c3aed"
    property bool showText: true
    property string label: ""
    property real animatedValue: 0

    Behavior on animatedValue { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
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

        // Gradient arc
        if (animatedValue > 0) {
            var gradient = ctx.createConicalGradient(cx, cy, startAngle)
            gradient.addColorStop(0, startColor)
            gradient.addColorStop(animatedValue / 100, endColor)

            // Glow
            ctx.save()
            ctx.shadowColor = glowColor
            ctx.shadowBlur = 12
            ctx.beginPath()
            ctx.arc(cx, cy, r, startAngle, endAngle)
            ctx.strokeStyle = gradient
            ctx.lineWidth = lineWidth
            ctx.lineCap = "round"
            ctx.stroke()
            ctx.restore()
        }
    }

    // Center text
    Column {
        anchors.centerIn: parent
        spacing: 2
        visible: showText

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(gauge.animatedValue) + "%"
            font.pixelSize: gauge.width * 0.22
            font.weight: Font.Bold
            color: "#f0eaff"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: gauge.label !== ""
            text: gauge.label
            font.pixelSize: gauge.width * 0.11
            color: "#6b5b95"
        }
    }
}
