import AppKit
import CoreText

let outPath = CommandLine.arguments[1]
let fontURL = URL(fileURLWithPath: CommandLine.arguments[2])
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

let width = 660
let height = 400

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("could not create bitmap rep") }
rep.size = NSSize(width: width, height: height)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let canvas = NSColor(calibratedRed: 0xFA / 255, green: 0xF8 / 255, blue: 0xF5 / 255, alpha: 1)
let espresso = NSColor(calibratedRed: 0x38 / 255, green: 0x2E / 255, blue: 0x2B / 255, alpha: 1)
let sage = NSColor(calibratedRed: 0xCF / 255, green: 0xE4 / 255, blue: 0x9C / 255, alpha: 1)

canvas.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

// Soft sage glow behind the icon row, echoing the app icon tile color
let glow = NSBezierPath(ovalIn: NSRect(x: 60, y: 130, width: 540, height: 180))
sage.withAlphaComponent(0.35).setFill()
glow.fill()

// Arrow from the app icon position to the Applications folder position
let arrowY: CGFloat = 210
let startX: CGFloat = 255
let endX: CGFloat = 400

let shaft = NSBezierPath()
shaft.lineWidth = 3
shaft.lineCapStyle = .round
espresso.setStroke()
shaft.move(to: NSPoint(x: startX, y: arrowY))
shaft.line(to: NSPoint(x: endX, y: arrowY))
shaft.stroke()

let head = NSBezierPath()
head.lineWidth = 3
head.lineCapStyle = .round
head.lineJoinStyle = .round
head.move(to: NSPoint(x: endX - 14, y: arrowY + 11))
head.line(to: NSPoint(x: endX, y: arrowY))
head.line(to: NSPoint(x: endX - 14, y: arrowY - 11))
head.stroke()

// Caption
let text = "Drag to Applications to install"
let font = NSFont(name: "Fredoka-Medium", size: 16) ?? NSFont.systemFont(ofSize: 16, weight: .medium)
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: espresso,
    .paragraphStyle: paragraph,
]
let attrString = NSAttributedString(string: text, attributes: attrs)
attrString.draw(in: NSRect(x: 0, y: 118, width: CGFloat(width), height: 24))

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not encode png")
}
try! pngData.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
