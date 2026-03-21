import AppKit

struct PercentageCircleWidget: StatusBarWidget {
    let icon: NSImage?
    let percentage: Double
    let tintColor: NSColor
    private let diameter: CGFloat = 18
    private let iconSize: CGFloat = 14
    private let gap: CGFloat = 3

    func widthForHeight(_ height: CGFloat) -> CGFloat {
        (icon != nil ? iconSize + gap : 0) + diameter
    }

    func draw(at origin: NSPoint, height: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        var x = origin.x

        if let icon {
            drawTemplateIcon(icon, in: NSRect(x: x, y: origin.y + (height - iconSize) / 2,
                                              width: iconSize, height: iconSize), ctx: ctx)
            x += iconSize + gap
        }

        let cx = x + diameter / 2
        let cy = origin.y + height / 2
        let radius = diameter / 2 - 1.5
        let lineWidth: CGFloat = 2.0

        // Track — matches menu bar foreground in dark/light mode
        ctx.setStrokeColor(NSColor.labelColor.withAlphaComponent(0.2).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
                   startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Fill arc
        if percentage > 0 {
            ctx.setStrokeColor(tintColor.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            let end = .pi / 2 - CGFloat(percentage / 100.0) * .pi * 2
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
                       startAngle: .pi / 2, endAngle: end, clockwise: true)
            ctx.strokePath()
            ctx.setLineCap(.butt)
        }
    }
}

/// Render an SF Symbol (template image) as labelColor — adapts to dark/light menu bar.
func drawTemplateIcon(_ icon: NSImage, in rect: NSRect, ctx: CGContext) {
    guard let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        icon.draw(in: rect)
        return
    }
    ctx.saveGState()
    // CGImage origin is bottom-left; flip vertically to match AppKit
    ctx.translateBy(x: rect.minX, y: rect.maxY)
    ctx.scaleBy(x: 1, y: -1)
    let r = CGRect(origin: .zero, size: rect.size)
    ctx.clip(to: r, mask: cgImage)
    NSColor.labelColor.setFill()
    ctx.fill(r)
    ctx.restoreGState()
}
