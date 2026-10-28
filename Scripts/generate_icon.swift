#!/usr/bin/env swift
// One-time generator for Resources/AppIcon.icns — run with:
//   swift Scripts/generate_icon.swift
// Re-run only if the icon design needs to change.
import AppKit

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()
let iconsetDir = repoRoot.appendingPathComponent("AppIcon.iconset")
let resourcesDir = repoRoot.appendingPathComponent("Resources")

try? FileManager.default.removeItem(at: iconsetDir)
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

func renderIcon(px: Int) -> NSImage {
    let size = NSSize(width: px, height: px)
    let image = NSImage(size: size)
    image.lockFocus()

    let bgRect = NSRect(origin: .zero, size: size)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: CGFloat(px) * 0.22, yRadius: CGFloat(px) * 0.22)
    NSColor.systemBlue.setFill()
    bgPath.fill()

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: CGFloat(px) * 0.56, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let tinted = symbol.copy() as! NSImage
        tinted.lockFocus()
        NSColor.white.set()
        NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
        tinted.unlockFocus()

        let symSize = tinted.size
        let origin = NSPoint(x: (size.width - symSize.width) / 2, y: (size.height - symSize.height) / 2)
        tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()
    return image
}

for (name, px) in sizes {
    let image = renderIcon(px: px)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(name)")
    }
    let dest = iconsetDir.appendingPathComponent("\(name).png")
    try png.write(to: dest)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", resourcesDir.appendingPathComponent("AppIcon.icns").path]
try process.run()
process.waitUntilExit()

try? FileManager.default.removeItem(at: iconsetDir)

print(process.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
