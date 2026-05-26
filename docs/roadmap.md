# resona ios roadmap

## Product Direction

resona ios is a native iOS music player that starts fully local — plays FLAC and MP3 files on your iPhone — and later gains mac mini streaming as a second source. v1 ships a complete local player. mac mini integration is a second milestone.

## Milestone 1: Local Player (current — feat/port-resona-core)

Goal: a working iOS music player for local FLAC/MP3 libraries that feels exactly like the resona desktop.

- xcode project via xcodegen (background audio, iOS 17+)
- SwiftData models: Track, LibraryRoot — identity by SHA256 path hash, matching resona desktop's `stable_identifier`
- design tokens: exact port of resona desktop palette, typography, and radii
- local file indexer: recursive FLAC/MP3 discovery, AVAsset metadata extraction, upsert with path-hash identity, artwork extraction and caching
- `PlaybackEngine` with AVPlayer: queue, auto-advance, shuffle, repeat
- `NowPlayingBridge`: lock screen controls, headphone transport via MPRemoteCommandCenter
- UI shell: tab bar (Library | Queue | Settings), MiniPlayer bar, FullPlayer sheet with vinyl rotation
- library views: tracks table (sort + search), albums grid, artists list
- settings: add library folders via file picker, scan status

## Milestone 2: Mac Mini Streaming (feat/stream-source)

Goal: add the resona desktop as a second audio source without breaking the local player.

- embedded HTTP server built in resona desktop (axum — separate branch in `/Users/rujulw/dev/resona`)
- `ServerSession` — manages base URL, health ping, retry policy
- `ServerDiscovery` — NWBrowser for `_resona._tcp`, manual IP fallback in Settings
- `RemoteLibrary` — fetches `/library` from server, caches locally
- `StreamSource` added to `PlaybackSource` protocol — AVPlayer with byte-range HTTP stream
- `LibraryStore` merges LocalLibrary + RemoteLibrary into one unified surface
- byte-range seeking verified against live server before calling done

## Milestone 3: Lock Screen and CarPlay

- validate lock screen and control center on device
- implement CarPlay template hierarchy (`CPTemplateApplicationScene`)
- test headphone and AirPlay transport commands

## Milestone 4: Playlists

- create, rename, delete playlists
- add/remove tracks, reorder
- persist in SwiftData
- queue handoff from playlist detail

## Deferred Scope

- Spotify import (desktop-only for now)
- analytics surfaces (top tracks, top artists)
- timbre audio intelligence
- offline pinning of streamed tracks
- gapless playback, crossfade, equalizer
- iPad layout
- widget extension

## Dependencies and Open Questions

- mac mini HTTP server: needs to be built in resona desktop before milestone 2 is possible; tracked in `/Users/rujulw/dev/resona`
- FLAC metadata edge cases: AVFoundation covers Vorbis comments — confirm behavior for malformed or missing tags before shipping
- local library roots: confirm scope for v1 (Files app picks only, or also Music app tracks via NSAppleMusicUsageDescription)
- security-scoped bookmarks: must survive app restart and iOS version upgrades — test on device before claiming indexer done
