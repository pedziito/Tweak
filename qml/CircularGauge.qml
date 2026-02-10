import QtQuick 2.15

Canvas {
    id: gauge
    width: 100
    height: 100

    property real value: 0
    property real lineWidth: 8
    property color trackColor: "#1e293b"
    property color startColor: "#6366f1"
    property color endColor: "#8b5cf6"
    property color glowColor: "#6366f1"
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

        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, fullAngle)
        ctx.strokeStyle = trackColor
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"
        ctx.stroke()

        if (animatedValue > 0) {
            var gradient = ctx.createConicalGradient(cx, cy, startAngle)
            gradient.addColorStop(0, startColor)
            gradient.addColorStop(animatedValue / 100, endColor)

            ctx.save()
            ctx.shadowColor = glowColor
            ctx.shadowBlur = 10
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
        spacing: 2
        visible: showText

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(gauge.animatedValue) + "%"
            font.pixelSize: gauge.width * 0.22
            font.weight: Font.Bold
            color: "#f1f5f9"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: gauge.label !== ""
            text: gauge.label
            font.pixelSize: gauge.width * 0.11
            color: "#64748b"
        }
    }
}
