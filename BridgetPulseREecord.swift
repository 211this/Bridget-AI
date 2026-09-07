import Foundation
import SwiftData

@Model
final class BridgetPulseRecord {
    var timestamp: Date
    var content: String

    init(timestamp: Date = .now, content: String) {
        self.timestamp = timestamp
        self.content = content
    }
}
