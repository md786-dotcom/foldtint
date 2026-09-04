import CoreServices
import Foundation

enum EventPathList {
    static func strings(from paths: CFArray, limit: Int) -> [String] {
        let total = CFArrayGetCount(paths)
        let count = min(limit, total)
        var result: [String] = []
        var index = 0
        while index < count {
            if let raw = CFArrayGetValueAtIndex(paths, index) {
                let text = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
                result.append(text)
            }
            index += 1
        }
        return result
    }
}
