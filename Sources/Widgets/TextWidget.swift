import AppKit

struct TextWidget: StatusBarWidget {
    let text: String
    private let attributes: [NSAttributedString.Key: Any]
    private let cachedSize: NSSize

    init(_ text: String, font: NSFont = .monospacedSystemFont(ofSize: 9, weight: .regular)) {
        self.text = text
        self.attributes = [.font: font, .foregroundColor: NSColor.labelColor]
        self.cachedSize = (text as NSString).size(withAttributes: self.attributes)
    }

    func widthForHeight(_ height: CGFloat) -> CGFloat {
        ceil(cachedSize.width) + 2
    }

    func draw(at origin: NSPoint, height: CGFloat) {
        let y = origin.y + (height - cachedSize.height) / 2
        (text as NSString).draw(at: NSPoint(x: origin.x + 1, y: y), withAttributes: attributes)
    }
}
