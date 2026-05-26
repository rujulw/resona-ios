import SwiftUI
import SwiftData

@main
struct ResonaIOSApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([Track.self, LibraryRoot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
