import SwiftUI
import SwiftData

@main
struct BridgetApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                BridgetPulseRecord.self
            ])
            let fileURL = URL.documentsDirectory.appending(path: "BridgetMasterVault.store")
            let configuration = ModelConfiguration("BridgetMasterVault", schema: schema, url: fileURL, allowsSave: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
