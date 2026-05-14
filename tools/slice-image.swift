import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 4 else {
    fputs("Usage: slice-image.swift input.jpg output-directory slice-count\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])
let sliceCount = Int(arguments[3]) ?? 10

guard let imageSource = NSImage(contentsOf: inputURL),
      let cgImage = imageSource.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("Could not load input image.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let width = cgImage.width
let height = cgImage.height
let baseSliceHeight = Int(ceil(Double(height) / Double(sliceCount)))

for index in 0..<sliceCount {
    let y = index * baseSliceHeight
    let sliceHeight = min(baseSliceHeight, height - y)
    guard sliceHeight > 0 else { continue }

    let cropRect = CGRect(x: 0, y: y, width: width, height: sliceHeight)
    guard let cropped = cgImage.cropping(to: cropRect) else {
        fputs("Could not crop slice \(index + 1).\n", stderr)
        exit(1)
    }

    let bitmap = NSBitmapImageRep(cgImage: cropped)
    guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
        fputs("Could not encode slice \(index + 1).\n", stderr)
        exit(1)
    }

    let filename = String(format: "portfolio-slice-%02d.jpg", index + 1)
    try data.write(to: outputURL.appendingPathComponent(filename))
}
