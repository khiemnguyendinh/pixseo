// Draws the PixSEO app icon at one size: scripts/make-icon.sh calls it for each iconset size.
// Usage: swift scripts/IconRenderer.swift <size> <output.png>
import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count == 3, let size = Double(args[1]) else {
    FileHandle.standardError.write("usage: IconRenderer <size> <out.png>\n".data(using: .utf8)!)
    exit(1)
}
let s = CGFloat(size)
let context = CGContext(data: nil, width: Int(s), height: Int(s), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// macOS icon grid: the body is ~80% of the canvas, with a soft shadow.
let inset = s * 0.1
let body = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
let radius = body.width * 0.225
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.03, color: CGColor(gray: 0, alpha: 0.35))
context.addPath(CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil))
context.clip()
let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [
    CGColor(srgbRed: 0.16, green: 0.42, blue: 0.98, alpha: 1),
    CGColor(srgbRed: 0.47, green: 0.25, blue: 0.93, alpha: 1),
] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: body.minX, y: body.maxY), end: CGPoint(x: body.maxX, y: body.minY), options: [])
context.restoreGState()

// White photo card.
let card = body.insetBy(dx: body.width * 0.17, dy: body.height * 0.2).offsetBy(dx: 0, dy: body.height * 0.05)
context.setFillColor(CGColor(gray: 1, alpha: 1))
context.addPath(CGPath(roundedRect: card, cornerWidth: card.width * 0.08, cornerHeight: card.width * 0.08, transform: nil))
context.fillPath()

// Mountains and sun inside the card.
let pic = card.insetBy(dx: card.width * 0.09, dy: card.height * 0.11)
context.saveGState()
context.addPath(CGPath(roundedRect: pic, cornerWidth: pic.width * 0.05, cornerHeight: pic.width * 0.05, transform: nil))
context.clip()
context.setFillColor(CGColor(srgbRed: 0.86, green: 0.91, blue: 1, alpha: 1))
context.fill(pic)
context.setFillColor(CGColor(srgbRed: 1, green: 0.74, blue: 0.2, alpha: 1))
let sun = pic.width * 0.13
context.fillEllipse(in: CGRect(x: pic.maxX - sun * 2.2, y: pic.maxY - sun * 2.2, width: sun * 1.4, height: sun * 1.4))
func mountain(_ peakX: CGFloat, _ peakY: CGFloat, _ halfWidth: CGFloat, _ color: CGColor) {
    context.setFillColor(color)
    context.move(to: CGPoint(x: pic.minX + pic.width * (peakX - halfWidth), y: pic.minY))
    context.addLine(to: CGPoint(x: pic.minX + pic.width * peakX, y: pic.minY + pic.height * peakY))
    context.addLine(to: CGPoint(x: pic.minX + pic.width * (peakX + halfWidth), y: pic.minY))
    context.fillPath()
}
mountain(0.3, 0.62, 0.45, CGColor(srgbRed: 0.27, green: 0.45, blue: 0.95, alpha: 1))
mountain(0.72, 0.45, 0.4, CGColor(srgbRed: 0.45, green: 0.3, blue: 0.9, alpha: 1))
context.restoreGState()

// "SEO" tag across the bottom of the card.
let tag = CGRect(x: body.midX - body.width * 0.2, y: body.minY + body.height * 0.08, width: body.width * 0.4, height: body.height * 0.16)
context.setFillColor(CGColor(srgbRed: 0.1, green: 0.78, blue: 0.47, alpha: 1))
context.addPath(CGPath(roundedRect: tag, cornerWidth: tag.height / 2, cornerHeight: tag.height / 2, transform: nil))
context.fillPath()
let font = CTFontCreateWithName("Helvetica-Bold" as CFString, tag.height * 0.62, nil)
let text = NSAttributedString(string: "SEO", attributes: [.font: font, .foregroundColor: NSColor.white])
let line = CTLineCreateWithAttributedString(text)
let width = CTLineGetTypographicBounds(line, nil, nil, nil)
context.textPosition = CGPoint(x: tag.midX - width / 2, y: tag.minY + tag.height * 0.27)
CTLineDraw(line, context)

let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
