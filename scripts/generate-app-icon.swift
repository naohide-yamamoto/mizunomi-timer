import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: generate-app-icon.swift <output.iconset> <output.icns>\n".utf8))
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let icnsURL = URL(fileURLWithPath: CommandLine.arguments[2])
if FileManager.default.fileExists(atPath: outputURL.path) {
    try FileManager.default.removeItem(at: outputURL)
}
if FileManager.default.fileExists(atPath: icnsURL.path) {
    try FileManager.default.removeItem(at: icnsURL)
}
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let sizes = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (pointSize, scale) in sizes {
    let pixelSize = pointSize * scale

    guard let bitmap = NSBitmapImageRep(
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
        FileHandle.standardError.write(Data("Could not create bitmap for icon size \(pointSize)@\(scale)x\n".utf8))
        exit(1)
    }

    bitmap.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawIcon(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("Could not render icon size \(pointSize)@\(scale)x\n".utf8))
        exit(1)
    }

    let suffix = scale == 1 ? "" : "@\(scale)x"
    let fileURL = outputURL.appendingPathComponent("icon_\(pointSize)x\(pointSize)\(suffix).png")
    try pngData.write(to: fileURL, options: .atomic)
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", "-o", icnsURL.path, outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    FileHandle.standardError.write(Data("iconutil failed with status \(iconutil.terminationStatus)\n".utf8))
    exit(iconutil.terminationStatus)
}

func drawIcon(in rect: NSRect) {
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
