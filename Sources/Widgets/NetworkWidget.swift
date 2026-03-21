import AppKit

/// Two-row stacked network widget: colored dot + download on top, upload on bottom.
/// Fixed width sized for max expected value to prevent shifting.
struct NetworkWidget: StatusBarWidget {
    let downText: String
    let upText: String

    private let font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
    private let dotSize: CGFloat = 5
    private let dotGap: CGFloat = 3
    private let rowGap: CGFloat = 1
    private let fixedWidth: CGFloat

    private static let maxTemplate = "1023 KB/s"

    init(down: String, up: String) {
        self.downText = down
        self.upText = up
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)]
        let arrowAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium)]
        let arrowWidth = ceil(("↓" as NSString).size(withAttributes: arrowAttrs).width)
        let textWidth = ceil((Self.maxTemplate as NSString).size(withAttributes: attrs).width)
        self.fixedWidth = arrowWidth + 3 + textWidth // arrow + gap + text
    }

    func widthForHeight(_ height: CGFloat) -> CGFloat { fixedWidth }

    func draw(at origin: NSPoint, height: CGFloat) {
        guard NSGraphicsContext.current?.cgContext != nil else { return }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ]
        let textHeight = ceil(("X" as NSString).size(withAttributes: attrs).height)
        let totalHeight = textHeight * 2 + rowGap
        let topY = origin.y + (height + totalHeight) / 2 - textHeight   // top row baseline
        let botY = topY - textHeight - rowGap                             // bottom row baseline

        let arrowAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor.labelColor,
        ]
        let arrowWidth = ceil(("↓" as NSString).size(withAttributes: arrowAttrs).width)
        let textX = origin.x + arrowWidth + dotGap

        // Down row
        let downWidth = ceil((downText as NSString).size(withAttributes: attrs).width)
        ("↓" as NSString).draw(at: NSPoint(x: origin.x, y: topY), withAttributes: arrowAttrs)
        (downText as NSString).draw(at: NSPoint(x: textX + (fixedWidth - arrowWidth - dotGap - downWidth), y: topY),
                                    withAttributes: attrs)

        // Up row
        let upWidth = ceil((upText as NSString).size(withAttributes: attrs).width)
        ("↑" as NSString).draw(at: NSPoint(x: origin.x, y: botY), withAttributes: arrowAttrs)
        (upText as NSString).draw(at: NSPoint(x: textX + (fixedWidth - arrowWidth - dotGap - upWidth), y: botY),
                                   withAttributes: attrs)
    }
}
