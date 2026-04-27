import AppKit

enum MenuBarIconFactory {
    static func makeTemplateIcon() -> NSImage {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size)

        for scale in [1, 2] {
            if let representation = makeBitmapRepresentation(scale: scale) {
                image.addRepresentation(representation)
            }
        }

        image.isTemplate = true
        return image
    }

    private static func makeBitmapRepresentation(scale: Int) -> NSBitmapImageRep? {
        let pointSize = 20
        let pixelSize = pointSize * scale
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        drawIcon(scale: CGFloat(scale))
        NSGraphicsContext.restoreGraphicsState()

        representation.size = NSSize(width: pointSize, height: pointSize)
        return representation
    }

    private static func drawIcon(scale: CGFloat) {
        NSColor.black.setStroke()
        let strokeWidth = 1.5 * scale

        let cap = NSBezierPath(
            roundedRect: scaledRect(x: 7, y: 15, width: 6, height: 2, scale: scale),
            xRadius: 1 * scale,
            yRadius: 1 * scale
        )
        cap.lineWidth = strokeWidth
        cap.stroke()

        let bottle = NSBezierPath(
            roundedRect: scaledRect(x: 6, y: 3, width: 8, height: 12, scale: scale),
            xRadius: 2.5 * scale,
            yRadius: 2.5 * scale
        )
        bottle.lineWidth = strokeWidth
        bottle.stroke()

        let wave = NSBezierPath()
        wave.move(to: scaledPoint(x: 6.5, y: 7, scale: scale))
        wave.curve(
            to: scaledPoint(x: 13.5, y: 7, scale: scale),
            controlPoint1: scaledPoint(x: 7.8, y: 8, scale: scale),
            controlPoint2: scaledPoint(x: 10.2, y: 6, scale: scale)
        )
        wave.lineWidth = strokeWidth
        wave.lineCapStyle = .round
        wave.stroke()
    }

    private static func scaledRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, scale: CGFloat) -> NSRect {
        NSRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
    }

    private static func scaledPoint(x: CGFloat, y: CGFloat, scale: CGFloat) -> NSPoint {
        NSPoint(x: x * scale, y: y * scale)
    }
}
