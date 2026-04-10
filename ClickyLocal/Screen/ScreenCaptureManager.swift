import Foundation
import AppKit
import CoreGraphics

final class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()

    private init() {}

    /// Capture the main display and return as base64-encoded JPEG
    func captureScreen() throws -> String {
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw ScreenCaptureError.noDisplay
        }

        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else {
            throw ScreenCaptureError.conversionFailed
        }
        return jpegData.base64EncodedString()
    }
}

enum ScreenCaptureError: Error, LocalizedError {
    case noDisplay
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .noDisplay: return "No display found"
        case .conversionFailed: return "Failed to convert screenshot"
        }
    }
}
