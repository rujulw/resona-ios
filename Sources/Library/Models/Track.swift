import Foundation
import SwiftData

/// A single audio file in the local library.
///
/// Identity: `id` is SHA256("track\0<relativePath>") computed by `stableIdentifier`.
/// Change detection: `sourceHash` is SHA256(relativePath + modificationDate ISO string).
/// File access: resolve via `LibraryRoot.bookmark` + `relativePath` — never store a per-file bookmark.
///
/// Normalization fallback chain (mirrors resona desktop):
///   title      → tag title       → filename stem (whitespace normalized)
///   artist     → tag artist      → albumArtist → nil
///   album      → tag album       → parent folder name → nil
///   albumArtist→ tag albumArtist → artist → nil
@Model
final class Track {
    @Attribute(.unique) var id: String
    var title: String
    var artist: String?
    var album: String?
    var albumArtist: String?
    var genre: String?
    var trackNumber: Int?
    var discNumber: Int?
    var year: Int?
    var durationSeconds: Double?
    var advisory: Bool?

    /// Absolute path to a cached JPEG in the app support artwork directory.
    /// Nil if no embedded artwork was found during indexing.
    var artworkPath: String?

    /// Path relative to the owning LibraryRoot's resolved URL.
    var relativePath: String

    /// "flac" or "mp3" — lowercase.
    var fileExtension: String

    /// `LibraryRoot.id` of the folder this track belongs to.
    var libraryRootId: String

    /// SHA256 of (relativePath + modificationDate ISO8601 string).
    /// Used to detect file changes without re-reading metadata on every scan.
    var sourceHash: String

    var indexedAt: Date

    init(
        id: String,
        title: String,
        relativePath: String,
        fileExtension: String,
        libraryRootId: String,
        sourceHash: String,
        artist: String? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        genre: String? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        year: Int? = nil,
        durationSeconds: Double? = nil,
        advisory: Bool? = nil,
        artworkPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.relativePath = relativePath
        self.fileExtension = fileExtension
        self.libraryRootId = libraryRootId
        self.sourceHash = sourceHash
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.genre = genre
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.year = year
        self.durationSeconds = durationSeconds
        self.advisory = advisory
        self.artworkPath = artworkPath
        self.indexedAt = Date()
    }
}
