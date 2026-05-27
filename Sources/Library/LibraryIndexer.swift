import AVFoundation
import CryptoKit
import Foundation
import SwiftData

@ModelActor
actor LibraryIndexer {

    // MARK: - Public types

    struct ScanResult: Sendable {
        let discovered: Int
        let inserted: Int
        let updated: Int
        let removed: Int
    }

    enum IndexerError: Error {
        case rootNotFound
        case bookmarkAccessDenied
    }

    // MARK: - Entry point

    func scan(rootId: String) async throws -> ScanResult {
        guard let root = try modelContext.fetch(
            FetchDescriptor<LibraryRoot>(predicate: #Predicate { $0.id == rootId })
        ).first else {
            throw IndexerError.rootNotFound
        }

        var isStale = false
        let rootURL = try URL(
            resolvingBookmarkData: root.bookmark,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        guard rootURL.startAccessingSecurityScopedResource() else {
            throw IndexerError.bookmarkAccessDenied
        }
        defer { rootURL.stopAccessingSecurityScopedResource() }

        if isStale {
            root.bookmark = try rootURL.bookmarkData(options: .minimalBookmark)
        }

        let files = discoverAudioFiles(in: rootURL)

        let existing = try modelContext.fetch(
            FetchDescriptor<Track>(predicate: #Predicate { $0.libraryRootId == rootId })
        )
        var byPath = Dictionary(uniqueKeysWithValues: existing.map { ($0.relativePath, $0) })

        var inserted = 0
        var updated = 0

        for fileURL in files {
            // Strip leading slash from rootURL.path to produce a clean relative path
            let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"
            let relativePath = String(fileURL.path.dropFirst(rootPath.count))
            let ext = fileURL.pathExtension.lowercased()

            let modDate = fileModificationDate(fileURL) ?? Date.distantPast
            let sourceHash = stableIdentifier(
                namespace: "source",
                value: relativePath + modDate.ISO8601Format()
            )

            if let existing = byPath.removeValue(forKey: relativePath) {
                guard existing.sourceHash != sourceHash else { continue }
                let meta = await extractMetadata(from: fileURL)
                let artworkPath = existing.artworkPath ?? (await saveArtwork(meta.artworkData, trackId: existing.id))
                existing.title = meta.title ?? titleFromFilename(fileURL)
                existing.artist = meta.artist
                existing.album = meta.album ?? albumFromParentFolder(fileURL)
                existing.albumArtist = meta.albumArtist
                existing.genre = meta.genre
                existing.trackNumber = meta.trackNumber
                existing.discNumber = meta.discNumber
                existing.year = meta.year
                existing.durationSeconds = meta.durationSeconds
                existing.artworkPath = artworkPath
                existing.sourceHash = sourceHash
                existing.indexedAt = Date()
                updated += 1
            } else {
                let trackId = stableIdentifier(namespace: "track", value: relativePath)
                let meta = await extractMetadata(from: fileURL)
                let artworkPath = await saveArtwork(meta.artworkData, trackId: trackId)
                let track = Track(
                    id: trackId,
                    title: meta.title ?? titleFromFilename(fileURL),
                    relativePath: relativePath,
                    fileExtension: ext,
                    libraryRootId: rootId,
                    sourceHash: sourceHash,
                    artist: meta.artist,
                    album: meta.album ?? albumFromParentFolder(fileURL),
                    albumArtist: meta.albumArtist,
                    genre: meta.genre,
                    trackNumber: meta.trackNumber,
                    discNumber: meta.discNumber,
                    year: meta.year,
                    durationSeconds: meta.durationSeconds,
                    artworkPath: artworkPath
                )
                modelContext.insert(track)
                inserted += 1
            }
        }

        let removed = byPath.count
        for stale in byPath.values {
            if let path = stale.artworkPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            modelContext.delete(stale)
        }

        root.lastScannedAt = Date()
        root.trackCount = files.count

        try modelContext.save()

        return ScanResult(
            discovered: files.count,
            inserted: inserted,
            updated: updated,
            removed: removed
        )
    }

    // MARK: - File discovery

    private func discoverAudioFiles(in root: URL) -> [URL] {
        var result: [URL] = []
        var stack: [URL] = [root]
        var visited: Set<String> = []

        while let dir = stack.popLast() {
            let canonical = (try? dir.resolvingSymlinksInPath()) ?? dir
            guard visited.insert(canonical.path).inserted else { continue }

            guard let entries = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for entry in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if isDir {
                    stack.append(entry)
                } else if ["flac", "mp3"].contains(entry.pathExtension.lowercased()) {
                    result.append(entry)
                }
            }
        }

        return result.sorted { $0.path < $1.path }
    }

    // MARK: - Metadata extraction

    private struct RawMetadata {
        var title: String?
        var artist: String?
        var album: String?
        var albumArtist: String?
        var genre: String?
        var trackNumber: Int?
        var discNumber: Int?
        var year: Int?
        var durationSeconds: Double?
        var artworkData: Data?
    }

    private func extractMetadata(from url: URL) async -> RawMetadata {
        let asset = AVURLAsset(url: url)
        var meta = RawMetadata()

        // Duration
        if let duration = try? await asset.load(.duration),
           !duration.isIndefinite,
           duration.seconds > 0 {
            meta.durationSeconds = duration.seconds
        }

        guard let allItems = try? await asset.load(.metadata) else { return meta }

        for item in allItems {
            // Common keyspace first
            if let key = item.commonKey {
                switch key {
                case .commonKeyTitle where meta.title == nil:
                    meta.title = try? await item.load(.stringValue)
                case .commonKeyArtist where meta.artist == nil:
                    meta.artist = try? await item.load(.stringValue)
                case .commonKeyAlbumName where meta.album == nil:
                    meta.album = try? await item.load(.stringValue)
                case .commonKeyArtwork where meta.artworkData == nil:
                    meta.artworkData = try? await item.load(.dataValue)
                default:
                    break
                }
            }

            // Format-specific keys not exposed in common keyspace
            guard let keyStr = item.key as? String else { continue }
            switch keyStr.uppercased() {
            case "TPE2", "ALBUMARTIST", "ALBUM ARTIST", "ALBUM_ARTIST"
                where meta.albumArtist == nil:
                meta.albumArtist = try? await item.load(.stringValue)

            case "TRCK", "TRACKNUMBER" where meta.trackNumber == nil:
                if let s = try? await item.load(.stringValue) {
                    meta.trackNumber = parseIntPrefix(s)
                }

            case "TPOS", "DISCNUMBER" where meta.discNumber == nil:
                if let s = try? await item.load(.stringValue) {
                    meta.discNumber = parseIntPrefix(s)
                }

            case "TDRC", "TYER", "DATE", "YEAR" where meta.year == nil:
                if let s = try? await item.load(.stringValue),
                   let y = Int(s.prefix(4)), y > 0 {
                    meta.year = y
                }

            case "TCON", "GENRE" where meta.genre == nil:
                meta.genre = try? await item.load(.stringValue)

            default:
                break
            }
        }

        // Normalization fallback chain (see Track.swift for full rules)
        meta.title      = meta.title.flatMap      { normalizeLabel($0) }
        meta.artist     = (meta.artist.flatMap     { normalizeLabel($0) })
                          ?? meta.albumArtist.flatMap { normalizeLabel($0) }
        meta.album      = meta.album.flatMap       { normalizeLabel($0) }
        meta.albumArtist = (meta.albumArtist.flatMap { normalizeLabel($0) })
                           ?? meta.artist
        meta.genre      = meta.genre.flatMap       { normalizeLabel($0) }

        return meta
    }

    // MARK: - Artwork

    private func saveArtwork(_ data: Data?, trackId: String) async -> String? {
        guard let data else { return nil }
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("artwork", isDirectory: true)
        let file = dir.appendingPathComponent("\(trackId).jpg")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: file, options: .atomic)
            return file.path
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func fileModificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }

    /// Parses the leading integer from strings like "3", "3/12", "03".
    private func parseIntPrefix(_ string: String) -> Int? {
        let digits = string.trimmingCharacters(in: .whitespaces).prefix(while: { $0.isNumber })
        return Int(digits).flatMap { $0 > 0 ? $0 : nil }
    }
}
