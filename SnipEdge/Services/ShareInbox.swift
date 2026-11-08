import Foundation
import UIKit

struct ShareInbox {
    static let appGroup = "group.com.zzoutuo.SnipEdge"
    private static let fileName = "pendingShare.jpg"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    static var pendingURL: URL? {
        guard let containerURL else { return nil }
        let url = containerURL.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func consume() -> UIImage? {
        guard let url = pendingURL else { return nil }
        defer { try? FileManager.default.removeItem(at: url) }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func write(_ image: UIImage) -> Bool {
        guard let containerURL, let data = image.jpegData(compressionQuality: 0.9) else { return false }
        let url = containerURL.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
