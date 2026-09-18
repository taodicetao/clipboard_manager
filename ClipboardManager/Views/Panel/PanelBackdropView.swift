import AppKit

final class PanelBackdropView: NSView {
    private let backdrop: NSView

    init(cornerRadius: CGFloat, content: NSView) {
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.cornerRadius = cornerRadius
            glass.style = .regular
            glass.contentView = content
            backdrop = glass
        } else {
            let effect = NSVisualEffectView()
            effect.material = .popover
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.maskImage = .roundedRectangleMask(cornerRadius: cornerRadius)
            content.frame = effect.bounds
            content.autoresizingMask = [.width, .height]
            effect.addSubview(content)
            backdrop = effect
        }
        super.init(frame: .zero)
        backdrop.frame = bounds
        backdrop.autoresizingMask = [.width, .height]
        addSubview(backdrop)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PanelBackdropView does not support NSCoder")
    }
}

private extension NSImage {
    static func roundedRectangleMask(cornerRadius: CGFloat) -> NSImage {
        let edge = cornerRadius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        image.resizingMode = .stretch
        return image
    }
}
