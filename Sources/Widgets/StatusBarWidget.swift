import AppKit

protocol StatusBarWidget {
    func draw(at origin: NSPoint, height: CGFloat)
    func widthForHeight(_ height: CGFloat) -> CGFloat
}
