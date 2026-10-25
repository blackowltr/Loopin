import AppKit
import CoreGraphics

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

ctx.interpolationQuality = .high

// 1. Draw rounded squircle background (Symmetrical: centered at 512, 512)
let squircleRect = CGRect(x: 80, y: 80, width: 864, height: 864)
let cornerRadius: CGFloat = 195
let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -30), blur: 48, color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor)
ctx.addPath(squirclePath)
ctx.fillPath()
ctx.restoreGState()

// Clip to squircle
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()

// Background Gradient (Deep midnight navy to vibrant cobalt, perfectly centered along x = 512)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    NSColor(red: 0.05, green: 0.07, blue: 0.14, alpha: 1.0).cgColor,
    NSColor(red: 0.08, green: 0.12, blue: 0.24, alpha: 1.0).cgColor,
    NSColor(red: 0.04, green: 0.05, blue: 0.11, alpha: 1.0).cgColor
] as CFArray
let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
}

// Background Radial Glow (Centered at 512, 512)
let glowColors = [
    NSColor(red: 0.0, green: 0.70, blue: 1.0, alpha: 0.35).cgColor,
    NSColor(red: 0.45, green: 0.20, blue: 0.95, alpha: 0.18).cgColor,
    NSColor.clear.cgColor
] as CFArray
if let radialGlow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 0.45, 1.0]) {
    ctx.drawRadialGradient(radialGlow, startCenter: CGPoint(x: 512, y: 512), startRadius: 10, endCenter: CGPoint(x: 512, y: 512), endRadius: 380, options: [])
}

// Symmetrical Concentric Pulse Rings (Centered at 512, 512)
for (idx, r) in [200.0, 290.0, 370.0].enumerated() {
    let alpha = 0.08 + Double(idx) * 0.06
    ctx.setLineWidth(3.5)
    ctx.setStrokeColor(NSColor(red: 0.1, green: 0.75, blue: 1.0, alpha: alpha).cgColor)
    ctx.strokeEllipse(in: CGRect(x: 512 - r, y: 512 - r, width: r * 2, height: r * 2))
}

ctx.saveGState()

// Perfectly Symmetrical Mouse Silhouette (Centered at 512, width 280, x: 372 to 652)
let mouseRect = CGRect(x: 372, y: 292, width: 280, height: 440)
let mouseRadius: CGFloat = 135
let mousePath = CGPath(roundedRect: mouseRect, cornerWidth: mouseRadius, cornerHeight: mouseRadius, transform: nil)

// Shadow for mouse
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 30, color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.45).cgColor)

// Mouse Body Gradient
let mouseColors = [
    NSColor(red: 0.16, green: 0.20, blue: 0.34, alpha: 0.95).cgColor,
    NSColor(red: 0.10, green: 0.13, blue: 0.22, alpha: 0.98).cgColor
] as CFArray
if let mouseGrad = CGGradient(colorsSpace: colorSpace, colors: mouseColors, locations: [0.0, 1.0]) {
    ctx.saveGState()
    ctx.addPath(mousePath)
    ctx.clip()
    ctx.drawLinearGradient(mouseGrad, start: CGPoint(x: 512, y: 732), end: CGPoint(x: 512, y: 292), options: [])
    ctx.restoreGState()
}

// Mouse Outline rim
ctx.addPath(mousePath)
ctx.setLineWidth(3.5)
ctx.setStrokeColor(NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.7).cgColor)
ctx.strokePath()

// Symmetrical Center Divider Line
ctx.setLineWidth(2)
ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.25).cgColor)
ctx.move(to: CGPoint(x: 512, y: 728))
ctx.addLine(to: CGPoint(x: 512, y: 570))
ctx.strokePath()

// Symmetrical Scroll Wheel / Touch Accent in Center (Centered at x = 512)
let wheelRect = CGRect(x: 502, y: 580, width: 20, height: 64)
let wheelPath = CGPath(roundedRect: wheelRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
ctx.setFillColor(NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.9).cgColor)
ctx.setShadow(offset: .zero, blur: 14, color: NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.8).cgColor)
ctx.addPath(wheelPath)
ctx.fillPath()

// Symmetrical Precision Upward Pointer Arrow (Axis of symmetry: x = 512)
let pointerPath = CGMutablePath()
pointerPath.move(to: CGPoint(x: 512, y: 490))       // Top tip
pointerPath.addLine(to: CGPoint(x: 555, y: 410))    // Right wing tip
pointerPath.addLine(to: CGPoint(x: 526, y: 422))    // Right notch
pointerPath.addLine(to: CGPoint(x: 526, y: 350))    // Right stem
pointerPath.addLine(to: CGPoint(x: 498, y: 350))    // Left stem
pointerPath.addLine(to: CGPoint(x: 498, y: 422))    // Left notch
pointerPath.addLine(to: CGPoint(x: 469, y: 410))    // Left wing tip
pointerPath.closeSubpath()

let arrowColors = [
    NSColor(red: 0.15, green: 0.90, blue: 1.0, alpha: 1.0).cgColor,
    NSColor(red: 0.0, green: 0.55, blue: 1.0, alpha: 1.0).cgColor
] as CFArray
if let arrowGrad = CGGradient(colorsSpace: colorSpace, colors: arrowColors, locations: [0.0, 1.0]) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 16, color: NSColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 0.85).cgColor)
    ctx.addPath(pointerPath)
    ctx.clip()
    ctx.drawLinearGradient(arrowGrad, start: CGPoint(x: 512, y: 490), end: CGPoint(x: 512, y: 350), options: [])
    ctx.restoreGState()
}

ctx.restoreGState()

// Inner Squircle Border Rim (Symmetrical)
ctx.addPath(squirclePath)
ctx.setLineWidth(3)
ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.20).cgColor)
ctx.strokePath()

ctx.restoreGState()
img.unlockFocus()

// Save PNG
let outPngUrl = URL(fileURLWithPath: "Clickr/Resources/AppIcon_1024.png")
if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: outPngUrl)
    print("Master symmetrical icon written to \(outPngUrl.path)")
}
