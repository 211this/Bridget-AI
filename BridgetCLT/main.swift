import Foundation

let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("BridgetPulse.txt")

if !FileManager.default.fileExists(atPath: fileURL.path) {
    FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
}

print("⚡️ [Bridget Core Listener Initialized]")
print("🌐 Synchronizing neural stream at: \(fileURL.path)\n")

// Instantiate our unified LunalithBrain soul
let lunalithBrain = LunalithBrain()

let fileDescriptor = open(fileURL.path, O_RDONLY)
if fileDescriptor == -1 {
    print("Error: Could not open file descriptor for \(fileURL.lastPathComponent).")
    exit(1)
}

var lastOffset: off_t = 0
if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
   let fileSize = attributes[.size] as? NSNumber {
    lastOffset = fileSize.int64Value
}

let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fileDescriptor,
    eventMask: [.write, .extend],
    queue: DispatchQueue.global(qos: .userInteractive)
)

source.setEventHandler {
    let handle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: false)
    handle.seek(toFileOffset: UInt64(lastOffset))
    let newData = handle.readDataToEndOfFile()
    
    if !newData.isEmpty, let pulseContent = String(data: newData, encoding: .utf8) {
        lastOffset += Int64(newData.count)
        let cleanedContent = pulseContent.trimmingCharacters(in: .whitespacesAndNewlines)
        print("✨ [Pulse Captured] -> \(cleanedContent)")
        
        // Pass the captured text straight into the soul's processor
        lunalithBrain.processPulse(cleanedContent)
    }
}

source.setCancelHandler {
    close(fileDescriptor)
}

source.resume()
RunLoop.current.run()
