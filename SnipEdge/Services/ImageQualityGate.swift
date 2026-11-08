import Foundation
import UIKit

enum ImageQualityGate {
    private static let workingWidth = 240

    static func evaluate(_ image: UIImage) -> AnalysisRefusal? {
        guard let cgImage = image.cgImage else { return .unreadableImage }
        guard min(cgImage.width, cgImage.height) >= 300 else { return .unreadableImage }
        guard let gray = grayscale(cgImage) else { return .unreadableImage }
        guard sharpness(gray.pixels, width: gray.width, height: gray.height) >= 6 else { return .unreadableImage }
        guard candleColumnCount(gray.pixels, width: gray.width, height: gray.height) >= 15 else { return .notAChart }
        return nil
    }

    private static func grayscale(_ image: CGImage) -> (pixels: [UInt8], width: Int, height: Int)? {
        let scale = Double(workingWidth) / Double(image.width)
        let width = workingWidth
        let height = max(Int(Double(image.height) * scale), 60)
        var buffer = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (buffer, width, height)
    }

    private static func sharpness(_ pixels: [UInt8], width: Int, height: Int) -> Double {
        guard width > 3, height > 3 else { return 0 }
        var values: [Double] = []
        values.reserveCapacity(width * height / 4)
        var y = 1
        while y < height - 1 {
            var x = 1
            while x < width - 1 {
                let index = y * width + x
                let center = Double(pixels[index])
                let left = Double(pixels[index - 1])
                let right = Double(pixels[index + 1])
                let up = Double(pixels[index - width])
                let down = Double(pixels[index + width])
                values.append(4 * center - left - right - up - down)
                x += 2
            }
            y += 2
        }
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        return sqrt(variance)
    }

    private static func candleColumnCount(_ pixels: [UInt8], width: Int, height: Int) -> Int {
        var chartColumns = 0
        var x = 2
        while x < width - 2 {
            var column: [Int] = []
            column.reserveCapacity(height)
            var y = 2
            while y < height - 2 {
                column.append(Int(pixels[y * width + x]))
                y += 1
            }
            guard !column.isEmpty else { x += 2; continue }
            let sorted = column.sorted()
            let median = sorted[sorted.count / 2]
            var longestRun = 0
            var currentRun = 0
            for value in column {
                if abs(value - median) > 32 {
                    currentRun += 1
                    longestRun = max(longestRun, currentRun)
                } else {
                    currentRun = 0
                }
            }
            if longestRun >= 6 { chartColumns += 1 }
            x += 2
        }
        return chartColumns
    }
}
