import SwiftUI
import SwiftData

@main
struct ResonaIOSApp: App {
    let modelContainer: ModelContainer
    let libraryStore: LibraryStore

    init() {
        let schema = Schema([Track.self, LibraryRoot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            modelContainer = container
            libraryStore = LibraryStore(container: container)
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(libraryStore)
        }
    }
}
