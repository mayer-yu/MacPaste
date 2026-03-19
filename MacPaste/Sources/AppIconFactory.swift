import AppKit

enum AppIconFactory {
    static func makeAppIcon(size: CGFloat = 256) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let radius = size * 0.22

        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.29, green: 0.53, blue: 0.98, alpha: 1.0),
            NSColor(calibratedRed: 0.40, green: 0.35, blue: 0.95, alpha: 1.0),
            NSColor(calibratedRed: 0.71, green: 0.32, blue: 0.95, alpha: 1.0)
        ])!

        let background = NSBezierPath(
            roundedRect: rect.insetBy(dx: size * 0.035, dy: size * 0.035),
            xRadius: radius,
            yRadius: radius
        )
        gradient.draw(in: background, angle: 295)

        NSGraphicsContext.current?.saveGraphicsState()
        background.addClip()
        NSColor.white.withAlphaComponent(0.16).setFill()
        let glow = NSBezierPath(ovalIn: NSRect(x: -size * 0.15, y: size * 0.48, width: size * 1.3, height: size * 0.7))
        glow.fill()
        NSGraphicsContext.current?.restoreGraphicsState()

        let clipboardRect = NSRect(x: size * 0.25, y: size * 0.20, width: size * 0.50, height: size * 0.60)
        let paper = NSBezierPath(roundedRect: clipboardRect, xRadius: size * 0.10, yRadius: size * 0.10)
        NSColor.white.withAlphaComponent(0.96).setFill()
        paper.fill()

        let clipRect = NSRect(x: size * 0.365, y: size * 0.70, width: size * 0.27, height: size * 0.14)
        let clip = NSBezierPath(roundedRect: clipRect, xRadius: size * 0.06, yRadius: size * 0.06)
        NSColor.white.setFill()
        clip.fill()

        let lineColor = NSColor(calibratedRed: 0.40, green: 0.45, blue: 0.70, alpha: 0.88)
        lineColor.setStroke()
        for i in 0..<3 {
            let y = size * (0.56 - CGFloat(i) * 0.11)
            let line = NSBezierPath()
            line.lineWidth = max(1, size * 0.03)
            line.lineCapStyle = .round
            line.move(to: NSPoint(x: size * 0.33, y: y))
            line.line(to: NSPoint(x: size * 0.67, y: y))
            line.stroke()
        }

        image.unlockFocus()
        return image
    }
}
