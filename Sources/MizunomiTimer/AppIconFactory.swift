import AppKit

enum AppIconFactory {
    static func makeApplicationIcon(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        image.unlockFocus()
        return image
    }

    static func draw(in rect: NSRect) {
        let cornerRadius = rect.width * 0.22
        let background = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor(calibratedRed: 0.12, green: 0.53, blue: 0.90, alpha: 1.0).setFill()
        background.fill()

        let bottleRect = NSRect(
            x: rect.midX - rect.width * 0.23,
            y: rect.minY + rect.height * 0.17,
            width: rect.width * 0.46,
            height: rect.height * 0.58
        )
        let capRect = NSRect(
            x: rect.midX - rect.width * 0.16,
            y: bottleRect.maxY - rect.height * 0.01,
            width: rect.width * 0.32,
            height: rect.height * 0.09
        )

        NSColor(calibratedWhite: 1.0, alpha: 0.95).setFill()
        NSBezierPath(roundedRect: capRect, xRadius: capRect.height * 0.45, yRadius: capRect.height * 0.45).fill()
        NSBezierPath(roundedRect: bottleRect, xRadius: bottleRect.width * 0.28, yRadius: bottleRect.width * 0.28).fill()

        let waterRect = NSRect(
            x: bottleRect.minX,
            y: bottleRect.minY,
            width: bottleRect.width,
            height: bottleRect.height * 0.55
        )
        let waterPath = NSBezierPath()
        waterPath.move(to: NSPoint(x: waterRect.minX, y: waterRect.minY + waterRect.height * 0.58))
        waterPath.curve(
            to: NSPoint(x: waterRect.maxX, y: waterRect.minY + waterRect.height * 0.62),
            controlPoint1: NSPoint(x: waterRect.minX + waterRect.width * 0.32, y: waterRect.maxY),
            controlPoint2: NSPoint(x: waterRect.minX + waterRect.width * 0.68, y: waterRect.minY + waterRect.height * 0.32)
        )
        waterPath.line(to: NSPoint(x: waterRect.maxX, y: waterRect.minY))
        waterPath.line(to: NSPoint(x: waterRect.minX, y: waterRect.minY))
        waterPath.close()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: bottleRect, xRadius: bottleRect.width * 0.28, yRadius: bottleRect.width * 0.28).addClip()
        NSColor(calibratedRed: 0.43, green: 0.91, blue: 1.0, alpha: 1.0).setFill()
        waterPath.fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}
