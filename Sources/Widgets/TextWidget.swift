import AppKit

struct TextWidget: StatusBarWidget {
    let text: String
    private let attributes: [NSAttributedString.Key: Any]
    private let fixedWidth: CGFloat   // sized for max expected string
    private let textHeight: CGFloat

    /// - sizedFor: template string used to reserve width (actual text right-aligns within it)
    init(_ text: String, sizedFor template: String, font: NSFont = .monospacedSystemFont(ofSize: 11, weight: .regular)) {
        self.text = text
        self.attributes = [.font: font, .foregroundColor: NSColor.labelColor]
        let templateSize = (template as NSString).size(withAttributes: self.attributes)
        self.fixedWidth = ceil(templateSize.width) + 2
        self.textHeight = templateSize.height
    }

    func widthForHeight(_ height: CGFloat) -> CGFloat { fixedWidth }

    func draw(at origin: NSPoint, height: CGFloat) {
        let actualWidth = ceil((text as NSString).size(withAttributes: attributes).width)
        // Right-align: start x = origin + fixedWidth - actualWidth
        let x = origin.x + fixedWidth - actualWidth
        let y = origin.y + (height - textHeight) / 2
        (text as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
    }
}
