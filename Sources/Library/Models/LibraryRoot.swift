import Foundation
import SwiftData

/// A folder the user has granted access to for music indexing.
///
/// Identity: `id` is SHA256("library-root\0<resolvedPath>") computed by `stableIdentifier`.
///
/// Access pattern:
///   1. Call `URL(resolvingBookmarkData: bookmark, options: .withoutUI, ...)`
///   2. Call `url.startAccessingSecurityScopedResource()` before any file I/O
///   3. Call `url.stopAccessingSecurityScopedResource()` when done
///   Bookmarks are regenerated on successful access to keep them fresh.
@Model
final class LibraryRoot {
    @Attribute(.unique) var id: String
    var displayName: String

    /// Security-scoped bookmark for the folder.
    /// Must be refreshed after each successful access to prevent staleness.
    var bookmark: Data

    /// SHA256 of the resolved absolute path at index time.
    /// Used to detect if the folder moved between sessions.
    var rootHash: String

    var addedAt: Date
    var lastScannedAt: Date?
    var trackCount: Int

    init(id: String, displayName: String, bookmark: Data, rootHash: String) {
        self.id = id
        self.displayName = displayName
        self.bookmark = bookmark
        self.rootHash = rootHash
        self.addedAt = Date()
        self.trackCount = 0
    }
}
