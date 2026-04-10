import Foundation
import ScreenCaptureKit
import AppKit

final class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()

    private init() {}

    /// Capture the main display and return as base64-encoded JPEG
    func captureScreen() async throws -> String {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw ScreenCaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = Int(display.width)
        config.height = Int(display.height)
        config.pixelFormat = kCVPixelFormatType_32BGRA

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        // Convert CGImage to JPEG base64
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
