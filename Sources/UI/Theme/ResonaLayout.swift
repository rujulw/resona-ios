import CoreFoundation

/// Spacing, radii, sizing, and typography constants.
/// All values derived from the resona desktop design language.
enum ResonaLayout {

    // MARK: - Corner radii
    /// List rows, nav items.
    static let radiusRow:  CGFloat = 4
    /// Artwork cards (album grid, track row thumbnails).
    static let radiusCard: CGFloat = 8
    /// Artist avatars are circular — use `.clipShape(.circle)`.

    // MARK: - Spacing
    static let spaceXS: CGFloat =  4
    static let spaceS:  CGFloat =  8
    static let spaceM:  CGFloat = 12
    static let spaceL:  CGFloat = 16
    static let spaceXL: CGFloat = 24
    static let spaceXXL: CGFloat = 32

    // MARK: - Artwork sizes
    /// Track row / mini player thumbnail.
    static let artworkRow:  CGFloat = 40
    /// Artist avatar.
    static let artworkAvatar: CGFloat = 44
    /// Album grid card side length.
    static let artworkCard: CGFloat = 160
    /// Full player large artwork.
    static let artworkFull: CGFloat = 280

    // MARK: - Mini player
    static let miniPlayerHeight: CGFloat = 64

    // MARK: - Typography
    /// Letter-spacing for section labels: 0.08em at 11pt ≈ 0.88pt.
    /// Use as `.tracking(ResonaLayout.sectionTracking)`.
    static let sectionTracking: CGFloat = 0.88
}
