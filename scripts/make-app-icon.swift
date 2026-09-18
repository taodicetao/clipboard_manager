#!/usr/bin/env swift
import AppKit

struct Slot {
    let points: Int
    let scale: Int
    var pixels: Int { points * scale }
    var filename: String { scale == 1 ? "AppIcon-\(points).png" : "AppIcon-\(points)@\(scale)x.png" }
}

let slots = [16, 32, 128, 256, 512].flatMap { [Slot(points: $0, scale: 1), Slot(points: $0, scale: 2)] }
let canvasSize = 1024
let iconInsetRatio = 100.0 / 1024.0
let cornerRatio = 0.2237

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func artworkBounds(of image: CGImage) -> CGRect {
    let sample = 512
    guard let context = CGContext(data: nil, width: sample, height: sample, bitsPerComponent: 8, bytesPerRow: sample * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return CGRect(x: 0, y: 0, width: image.width, height: image.height) }
    context.draw(image, in: CGRect(x: 0, y: 0, width: sample, height: sample))
    guard let data = context.data else { return CGRect(x: 0, y: 0, width: image.width, height: image.height) }
    let pixels = data.bindMemory(to: UInt8.self, capacity: sample * sample * 4)
    var minX = sample, minY = sample, maxX = -1, maxY = -1
    for y in 0..<sample {
        for x in 0..<sample {
            let offset = (y * sample + x) * 4
            let r = Int(pixels[offset]), g = Int(pixels[offset + 1]), b = Int(pixels[offset + 2]), a = Int(pixels[offset + 3])
            let isBackground = a < 16 || (min(r, g, b) >= 185 && max(r, g, b) - min(r, g, b) <= 24)
            if !isBackground {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
    }
    guard maxX >= minX, maxY >= minY else { return CGRect(x: 0, y: 0, width: image.width, height: image.height) }
    let scaleX = Double(image.width) / Double(sample), scaleY = Double(image.height) / Double(sample)
    let rect = CGRect(x: Double(minX) * scaleX, y: Double(sample - 1 - maxY) * scaleY, width: Double(maxX - minX + 1) * scaleX, height: Double(maxY - minY + 1) * scaleY)
    return rect.insetBy(dx: rect.width * 0.015, dy: rect.height * 0.015).integral
}

func squareCrop(_ image: CGImage) -> CGImage {
    let bounds = artworkBounds(of: image)
    let side = min(bounds.width, bounds.height)
    let square = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side).integral
    return image.cropping(to: square) ?? image
}

func render(_ artwork: CGImage, size: Int) -> CGImage {
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fail("Could not create canvas") }
    let inset = Double(size) * iconInsetRatio
    let iconRect = CGRect(x: inset, y: inset, width: Double(size) - inset * 2, height: Double(size) - inset * 2)
    let radius = iconRect.width * cornerRatio
    context.interpolationQuality = .high
    context.addPath(CGPath(roundedRect: iconRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.clip()
    context.draw(artwork, in: iconRect)
    guard let image = context.makeImage() else { fail("Could not render \(size)px icon") }
    return image
}

func writePNG(_ image: CGImage, to url: URL) {
    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else { fail("Could not encode \(url.lastPathComponent)") }
    do {
        try data.write(to: url, options: .atomic)
    } catch {
        fail("Could not write \(url.path): \(error.localizedDescription)")
    }
}

func writeContents(to directory: URL) {
    let images = slots.map { slot -> [String: String] in
        ["filename": slot.filename, "idiom": "mac", "scale": "\(slot.scale)x", "size": "\(slot.points)x\(slot.points)"]
    }
    let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    guard let data = try? JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]) else { fail("Could not encode Contents.json") }
    do {
        try data.write(to: directory.appendingPathComponent("Contents.json"), options: .atomic)
    } catch {
        fail("Could not write Contents.json: \(error.localizedDescription)")
    }
}

let arguments = CommandLine.arguments.dropFirst()
guard let inputPath = arguments.first else {
    fail("usage: make-app-icon.swift <artwork image> [appiconset directory]")
}
let outputPath = arguments.dropFirst().first ?? "ClipboardManager/Assets.xcassets/AppIcon.appiconset"
let inputURL = URL(fileURLWithPath: inputPath)
let outputURL = URL(fileURLWithPath: outputPath, isDirectory: true)

guard let source = NSImage(contentsOf: inputURL)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fail("Could not read image at \(inputPath)")
}
let artwork = squareCrop(source)
if artwork.width < canvasSize {
    FileHandle.standardError.write(Data("warning: artwork is only \(artwork.width)px wide after trimming; 1024px or more is recommended\n".utf8))
}

do {
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
    for existing in try FileManager.default.contentsOfDirectory(at: outputURL, includingPropertiesForKeys: nil) where existing.pathExtension == "png" {
        try FileManager.default.removeItem(at: existing)
    }
} catch {
    fail("Could not prepare \(outputURL.path): \(error.localizedDescription)")
}
for slot in slots {
    writePNG(render(artwork, size: slot.pixels), to: outputURL.appendingPathComponent(slot.filename))
}
writeContents(to: outputURL)
print("Wrote \(slots.count) icons from \(artwork.width)×\(artwork.height)px artwork to \(outputURL.path)")
