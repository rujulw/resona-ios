import CryptoKit
import Foundation

/// Produces a stable, namespaced SHA256 identifier.
///
/// Mirrors resona desktop's `stable_identifier(namespace, value)` in
/// `server/src/library/normalization/helpers.rs` exactly:
///   - input bytes: namespace + null byte + value
///   - output: "<namespace>-<lowercase hex SHA256>"
func stableIdentifier(namespace: String, value: String) -> String {
    var hasher = SHA256()
    hasher.update(data: Data(namespace.utf8))
    hasher.update(data: Data([0]))
    hasher.update(data: Data(value.utf8))
    let digest = hasher.finalize()
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    return "\(namespace)-\(hex)"
}

/// Normalizes a raw metadata string: trims whitespace, collapses internal runs.
func normalizeLabel(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return trimmed
        .components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
}

/// Derives a display title from a file URL when tags are absent.
/// Strips extension, normalizes whitespace — mirrors resona's filename-stem fallback.
func titleFromFilename(_ url: URL) -> String {
    let stem = url.deletingPathExtension().lastPathComponent
    let normalized = stem
        .components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    return normalized.isEmpty ? url.lastPathComponent : normalized
}

/// Derives an album name from the parent folder when the album tag is absent.
/// Mirrors resona's parent-folder album fallback.
func albumFromParentFolder(_ url: URL) -> String? {
    let folder = url.deletingLastPathComponent().lastPathComponent
    return normalizeLabel(folder)
}
