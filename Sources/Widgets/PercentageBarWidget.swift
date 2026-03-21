import AppKit

struct PercentageBarWidget: StatusBarWidget {
    let icon: NSImage?
    let percentage: Double
    let tintColor: NSColor
    private let barWidth: CGFloat = 30
    private let barHeight: CGFloat = 8
    private let iconSize: CGFloat = 12
    private let gap: CGFloat = 2

    func widthForHeight(_ height: CGFloat) -> CGFloat {
        (icon != nil ? iconSize + gap : 0) + barWidth
    }

    func draw(at origin: NSPoint, height: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        var x = origin.x

        if let icon {
            drawTemplateIcon(icon, in: NSRect(x: x, y: origin.y + (height - iconSize) / 2,
                                              width: iconSize, height: iconSize), ctx: ctx)
            x += iconSize + gap
        }

        let barY = origin.y + (height - barHeight) / 2

        ctx.setFillColor(NSColor.labelColor.withAlphaComponent(0.2).cgColor)
        let bgPath = CGPath(roundedRect: CGRect(x: x, y: barY, width: barWidth, height: barHeight),
                            cornerWidth: 2, cornerHeight: 2, transform: nil)
        ctx.addPath(bgPath)
        ctx.fillPath()

        let fillWidth = barWidth * CGFloat(percentage / 100.0)
        if fillWidth > 0 {
            ctx.setFillColor(tintColor.cgColor)
            let fillPath = CGPath(roundedRect: CGRect(x: x, y: barY, width: fillWidth, height: barHeight),
                                  cornerWidth: 2, cornerHeight: 2, transform: nil)
            ctx.addPath(fillPath)
            ctx.fillPath()
        }
    }
}
