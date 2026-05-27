import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class LibraryStore {

    // MARK: - State

    enum ScanState: Equatable {
        case idle
        case scanning
        case error(String)
    }

    private(set) var tracks: [Track] = []
    private(set) var roots: [LibraryRoot] = []
    private(set) var scanState: ScanState = .idle

    // MARK: - Init

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Library access

    func load() async {
        let ctx = ModelContext(container)
        do {
            roots = try ctx.fetch(FetchDescriptor<LibraryRoot>(
                sortBy: [SortDescriptor(\LibraryRoot.addedAt)]
            ))
            var desc = FetchDescriptor<Track>(
                sortBy: [SortDescriptor(\Track.title)]
            )
            desc.propertiesToFetch = [
                \Track.id,
                \Track.title,
                \Track.artist,
                \Track.album,
                \Track.albumArtist,
                \Track.durationSeconds,
                \Track.artworkPath,
                \Track.trackNumber,
                \Track.discNumber,
                \Track.year,
                \Track.fileExtension,
                \Track.relativePath,
                \Track.libraryRootId,
            ]
            tracks = try ctx.fetch(desc)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }

    // MARK: - Root management

    func addRoot(url: URL, bookmark: Data) async {
        let rootId = stableIdentifier(namespace: "library-root", value: url.path)
        let displayName = url.lastPathComponent.isEmpty ? "Music" : url.lastPathComponent
        let rootHash = stableIdentifier(namespace: "path", value: url.path)

        let ctx = ModelContext(container)
        let existing = try? ctx.fetch(
            FetchDescriptor<LibraryRoot>(predicate: #Predicate { $0.id == rootId })
        )
        guard existing?.isEmpty != false else { return }

        let root = LibraryRoot(
            id: rootId,
            displayName: displayName,
            bookmark: bookmark,
            rootHash: rootHash
        )
        ctx.insert(root)
        try? ctx.save()

        await load()
        await scan(rootIds: [rootId])
    }

    func removeRoot(_ root: LibraryRoot) async {
        let rootId = root.id
        let ctx = ModelContext(container)

        let tracksToDelete = (try? ctx.fetch(
            FetchDescriptor<Track>(predicate: #Predicate { $0.libraryRootId == rootId })
        )) ?? []

        for track in tracksToDelete {
            if let path = track.artworkPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            ctx.delete(track)
        }

        if let existing = try? ctx.fetch(
            FetchDescriptor<LibraryRoot>(predicate: #Predicate { $0.id == rootId })
        ).first {
            ctx.delete(existing)
        }

        try? ctx.save()
        await load()
    }

    // MARK: - Scanning

    func scanAll() async {
        let ids = roots.map { $0.id }
        await scan(rootIds: ids)
    }

    private func scan(rootIds: [String]) async {
        guard !rootIds.isEmpty else { return }
        scanState = .scanning

        let indexer = LibraryIndexer(modelContainer: container)
        for id in rootIds {
            do {
                _ = try await indexer.scan(rootId: id)
            } catch {
                scanState = .error(error.localizedDescription)
                return
            }
        }

        scanState = .idle
        await load()
    }
}
