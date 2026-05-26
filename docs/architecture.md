# resona ios architecture

## Overview

resona ios is a native SwiftUI client that presents a unified music library from two sources: local on-device files and a streaming resona desktop server. Both sources share one playback engine, one queue, and one UI surface. The architecture is designed so source-switching is transparent to the view layer.

## System Context

```text
SwiftUI views
  -> @Observable view models / environment objects
  -> PlaybackEngine (AVPlayer, queue, NowPlayingBridge)
  -> LibraryStore (RemoteLibrary + LocalLibrary merged)
  -> ServerSession (HTTP to resona mac mini)
  -> AVFoundation + MediaPlayer framework
```

## Source Model

### `PlaybackSource` Protocol

All audio enters through one protocol. Views and the queue never care which source backs a track.

```
PlaybackSource
  ├── LocalSource   — AVPlayer with local file URL (on-device)
  └── StreamSource  — AVPlayer with HTTP URL from resona server
                      (byte-range streaming required for seeking)
```

`PlaybackEngine` holds the active `AVPlayer` instance. When a track's source changes mid-queue (mixed local + remote queue), the engine swaps player items without breaking transport state.

## Module Layout

### `Sources/Server/`

Network boundary to the resona mac mini.

- `ServerSession` — base URL management, health ping, retry policy. All HTTP calls go through this; views and stores never use raw `URLSession` directly.
- `ServerDiscovery` — Bonjour browser for `_resona._tcp`, emits resolved URL. Falls back gracefully when mDNS is unavailable.
- `ServerSettingsStore` — persists manual IP/port entry from Settings view.

API surface (contracts defined in the resona desktop repo):

| Endpoint | Purpose |
|---|---|
| `GET /library` | full library JSON — tracks, albums, artists, playlists |
| `GET /stream/:id` | audio stream, byte-range capable |
| `GET /artwork/:id` | album art JPEG/PNG |
| `GET /now-playing` | SSE stream for real-time playback state (optional) |

### `Sources/Library/`

Merges remote and local track catalogs into one surface.

```
LibraryStore              — @Observable actor, single source of truth for library data
  ├── RemoteLibrary       — fetches /library from ServerSession, caches locally
  └── LocalLibrary        — indexes on-device audio files (Music app / Files / imported)
```

`LibraryStore` exposes unified `[Track]`, `[Album]`, `[Artist]`, `[Playlist]` arrays. Each `Track` carries a `source: PlaybackSource` field. Views never branch on source type.

Track identity rules:
- Remote tracks: server-assigned UUID string
- Local tracks: stable hash of file path + title + artist metadata
- IDs are not globally unique across sources — never compare remote ID against local ID

### `Sources/Playback/`

Owns all playback state. Views observe; views do not own transport truth.

```
PlaybackEngine              — @Observable @MainActor, injected via SwiftUI environment
  ├── QueueManager          — ordered track list, auto-advance, shuffle, repeat modes
  ├── NowPlayingBridge      — MPNowPlayingInfoCenter + MPRemoteCommandCenter wiring
  └── PlaybackSession       — play history, position persistence across launches
```

`PlaybackEngine` is the single source of truth for:
- active track identity
- transport mode (play / pause / stopped)
- playback position and duration
- queue order

Views observe `PlaybackEngine` directly via `@Environment`. No prop-drilling, no duplicated state.

AVPlayer configuration:
- local tracks: `AVPlayerItem(url: localFileURL)`
- stream tracks: `AVPlayerItem(url: httpStreamURL)` — server must respond to `Range:` headers or seeking breaks

### `Sources/UI/`

View layer. SwiftUI only. UIKit only where AVKit demands it.

```
AppRoot
  ├── TabBar               — Home | Library | Search | Settings
  ├── MiniPlayer           — persistent bottom bar, taps → FullPlayer sheet
  └── FullPlayer           — sheet: artwork, transport, queue panel

Home                       — recents, playlists, albums rows
Library                    — Tracks | Albums | Artists | Playlists tabs
Search                     — cross-entity, client-side scored
Settings                   — server discovery, manual IP, local library roots
```

Navigation model: tab bar at root, sheet presentation for full player, push navigation within tabs.

## Concurrency Model

Swift 6 strict concurrency enforced throughout.

- `LibraryStore`, `ServerSession`, `ServerDiscovery` — `actor` for shared mutable state
- `PlaybackEngine` — `@Observable @MainActor`
- All `@Observable` view models — `@MainActor`
- No `DispatchQueue.main.async` — use `await MainActor.run` or `@MainActor` annotation

## Data Persistence

- `SwiftData` — local library index cache, server session metadata
- `UserDefaults` — lightweight settings (manual IP, last-used server, display prefs)
- Position persistence: `PlaybackSession` writes last-played track + position on background task

## Lock Screen and CarPlay

`NowPlayingBridge` wires:
- `MPNowPlayingInfoCenter.default()` — active track metadata, artwork, position
- `MPRemoteCommandCenter` — play, pause, next, previous, seek commands from lock screen / headphones / CarPlay

CarPlay requires a separate `CPTemplateApplicationScene` entitlement and a dedicated template hierarchy. Lock screen integration works in simulator; CarPlay requires device + vehicle or Xcode CarPlay simulator.

## Server Discovery Flow

1. `ServerDiscovery` starts a `NWBrowser` for `_resona._tcp`
2. On resolution, emits host + port → `ServerSession` constructs base URL
3. If mDNS fails (VPN, enterprise router), `ServerSettingsStore` provides manual IP
4. `ServerSession` pings `/library` to confirm connectivity before marking server ready
5. Settings view always exposes manual IP entry as a fallback

## Playback Flow (Streamed Track)

1. User selects a remote track in Library
2. `LibraryStore` resolves `StreamSource(url: serverSession.streamURL(id:))`
3. `PlaybackEngine.play(track:)` creates `AVPlayerItem` from stream URL
4. `AVPlayer` issues byte-range HTTP requests to resona server
5. `NowPlayingBridge` updates `MPNowPlayingInfoCenter` with track metadata + artwork
6. Transport commands from lock screen route through `MPRemoteCommandCenter` back to `PlaybackEngine`

## Playback Flow (Local Track)

1. User selects a local track
2. `LocalLibrary` resolves local file URL
3. `PlaybackEngine.play(track:)` creates `AVPlayerItem` from file URL
4. Identical transport flow from that point — source is transparent to the engine surface

## Performance Constraints

- No full-library hydration on app boot — paginate or lazy-load from `LibraryStore`
- Artwork fetched on demand, cached with `URLCache`
- Background audio session required (`AVAudioSession.Category.playback`) — no interruption on screen lock
- Background task for position persistence — short-lived, does not keep app alive indefinitely
