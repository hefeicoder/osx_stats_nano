import AppKit

struct PercentageCircleWidget: StatusBarWidget {
    let icon: NSImage?
    let percentage: Double
    let tintColor: NSColor
    private let diameter: CGFloat = 14
    private let iconSize: CGFloat = 12
    private let gap: CGFloat = 2

    func widthForHeight(_ height: CGFloat) -> CGFloat {
        (icon != nil ? iconSize + gap : 0) + diameter
    }

    func draw(at origin: NSPoint, height: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        var x = origin.x

        if let icon = icon {
            let iconRect = NSRect(x: x, y: origin.y + (height - iconSize) / 2, width: iconSize, height: iconSize)
            icon.draw(in: iconRect)
            x += iconSize + gap
        }

        let centerX = x + diameter / 2
        let centerY = origin.y + height / 2
        let radius = diameter / 2 - 1.5
        let lineWidth: CGFloat = 2.5

        ctx.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius,
                   startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        if percentage > 0 {
            ctx.setStrokeColor(tintColor.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            let startAngle: CGFloat = .pi / 2
            let endAngle = startAngle - CGFloat(percentage / 100.0) * .pi * 2
            ctx.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius,
                       startAngle: startAngle, endAngle: endAngle, clockwise: true)
            ctx.strokePath()
            ctx.setLineCap(.butt)
        }
    }
}
