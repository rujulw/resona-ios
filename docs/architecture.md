# resona ios architecture

## Overview

resona ios v1 is a local-first native iOS music player. it plays FLAC and MP3 files stored on the device. mac mini streaming is a planned second milestone — not part of the current architecture. the system is designed so streaming can be added as a second `PlaybackSource` conformer without restructuring the engine or UI.

## System Context (v1 — local only)

```text
SwiftUI views
  -> @Observable view models / @Environment
  -> PlaybackEngine (AVPlayer, QueueManager, NowPlayingBridge)
  -> LibraryStore (LocalLibrary only in v1)
  -> LibraryIndexer (AVAsset metadata, file discovery, SwiftData)
  -> AVFoundation + MediaPlayer framework + CryptoKit
```

## Source Model

### `PlaybackSource` Protocol

Introduced now with one conformer. `StreamSource` added in milestone 2 without touching the engine.

```
PlaybackSource (protocol)
  └── LocalSource   — resolves a security-scoped file URL from a LibraryRoot bookmark
```

`PlaybackEngine` loads an `AVPlayerItem` from whatever URL `PlaybackSource` resolves. Views never see source type.

## Module Layout

### `Sources/Library/`

Owns the local audio catalog.

```
LibraryStore (actor)          — public surface: [Track], [Album], [Artist], scan triggers
  └── LibraryIndexer (actor)  — file discovery, metadata extraction, SwiftData upsert

SwiftData models:
  Track        — all metadata fields + fileBookmark (Data) + artworkPath + sourceHash
  LibraryRoot  — security-scoped bookmark (Data) + displayName + rootHash
```

**Track identity:** SHA256 hash of `"track\0<relative-path-from-root>"` — same strategy as resona desktop's `stable_identifier(namespace, value)`. Implemented with `CryptoKit.SHA256`.

**Metadata extraction pipeline:**
1. Start security-scoped access on `LibraryRoot.bookmark`
2. Walk directory tree recursively via `FileManager` — collect `.flac` and `.mp3` files
3. For each file: load `AVAsset`, await `.metadata`, extract title/artist/album/albumArtist/genre/trackNumber/discNumber/year/duration via `AVMetadataItem`
4. Extract artwork from `commonKeyArtwork`, write JPEG to app support directory, store path on `Track`
5. Compute `sourceHash` from file URL + modification date
6. SwiftData: insert new tracks, update changed (hash mismatch), delete stale (path gone)

**Normalization fallback chain (matches resona desktop):**
- `title` → tag title → filename stem (whitespace normalized)
- `artist` → tag artist → tag albumArtist → nil
- `album` → tag album → parent folder name → nil
- `albumArtist` → tag albumArtist → tag artist → nil

**Album aggregation:** Albums are not persisted — computed from `[Track]` at query time, grouped by `(album, albumArtist)`. Same approach as resona: no separate album table for v1.

### `Sources/Playback/`

Owns all playback state. Views observe; views do not own transport truth.

```
PlaybackEngine (@Observable @MainActor)
  ├── QueueManager          — [Track], currentIndex, auto-advance, shuffle (Fisher-Yates), repeat (off/one/all)
  ├── NowPlayingBridge      — MPNowPlayingInfoCenter + MPRemoteCommandCenter
  └── PlaybackSession       — UserDefaults: last trackId + position, restored on launch
```

**AVPlayer lifecycle:**
- `play(track:)` → resolve `LocalSource` bookmark → create `AVPlayerItem(url:)` → `player.replaceCurrentItem`
- `AVPlayerItem.didPlayToEndTime` notification → `QueueManager.advance()` → next track
- `AVAudioSession.Category.playback` set at launch — enables background audio, silences on ringer mute

**`NowPlayingBridge` responsibilities:**
- `MPNowPlayingInfoCenter.default()` updated on every track change and seek: title, artist, album, `MPMediaItemArtwork`, elapsed time, duration, playback rate
- `MPRemoteCommandCenter`: play, pause, togglePlayPause, nextTrack, previousTrack, `changePlaybackPositionCommand` — all route through `PlaybackEngine` as the single mutation path

### `Sources/UI/`

SwiftUI only. No UIKit.

```
AppRoot (@main)
  └── TabView
        ├── LibraryTab
        │     ├── TracksView        — LazyVStack table, sort picker, inline search
        │     ├── AlbumsView        — LazyVGrid 2-col artwork cards
        │     └── ArtistsView       — List with circular avatars → AlbumDetailView
        ├── QueueView               — current queue list, now-playing highlighted
        └── SettingsView            — library roots, scan status, format info

MiniPlayer                          — persistent overlay above tab bar
FullPlayer                          — sheet with artwork, vinyl rotation, transport, queue panel
```

**Navigation:** `TabView` at root. Push navigation within Library tab via `NavigationStack`. `FullPlayer` as `.sheet` on `MiniPlayer` tap. No drawer, no hamburger.

## Concurrency Model

Swift 6 strict concurrency.

- `LibraryStore`, `LibraryIndexer` — `actor`
- `PlaybackEngine` — `@Observable @MainActor`
- AVAsset metadata loading — `await asset.loadMetadata(...)` (async)
- File scanning — `Task { }` launched from `LibraryStore`, progress published via `AsyncStream`
- No `DispatchQueue.main.async` — `@MainActor` annotation or `await MainActor.run`

## Persistence

- `SwiftData` — `Track`, `LibraryRoot` models. Container in app support directory.
- `UserDefaults` — playback position, last track ID, display preferences.
- Artwork — JPEG files written to `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!/artwork/`.
- Security-scoped bookmarks — stored as `Data` on `LibraryRoot`. Started/stopped around all file access.

## Lock Screen

`NowPlayingBridge` wires `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`. Requires device for meaningful testing — simulator lock screen behavior is incomplete.

## Milestone 2 Extension Points

When mac mini streaming is added:
- `StreamSource: PlaybackSource` added — `PlaybackEngine` unchanged
- `RemoteLibrary` added alongside `LocalLibrary` in `LibraryStore`
- `ServerSession` and `ServerDiscovery` added to a new `Sources/Server/` module
- `LibraryStore` gains a merge step — no structural change to `PlaybackEngine` or UI

Nothing in the v1 architecture needs to be undone. The source protocol and module boundaries are already shaped to accept the second source.
