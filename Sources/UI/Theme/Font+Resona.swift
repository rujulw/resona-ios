import SwiftUI

extension Font {
    /// 11pt regular — section labels, uppercase/lowercase enforced at call site.
    /// Apply `.tracking(ResonaLayout.sectionTracking)` alongside this.
    static let resonaSection   = Font.system(size: 11, weight: .regular)

    /// 14pt medium — primary content: track titles, album names.
    static let resonaPrimary   = Font.system(size: 14, weight: .medium)

    /// 12pt regular — secondary metadata: artist, duration, counts.
    static let resonaSecondary = Font.system(size: 12, weight: .regular)

    /// 10pt regular — micro labels: track numbers, queue position indicators.
    static let resonaMicro     = Font.system(size: 10, weight: .regular)
}
