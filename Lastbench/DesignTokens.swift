import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #2C271B
    static let bg = Color(red: 0.172549, green: 0.152941, blue: 0.105882)
    static let bgHex = "#2C271B"
    /// #3A3D29
    static let surface = Color(red: 0.227451, green: 0.239216, blue: 0.160784)
    static let surfaceHex = "#3A3D29"
    /// #F4F3F1
    static let ink = Color(red: 0.956863, green: 0.952941, blue: 0.945098)
    static let inkHex = "#F4F3F1"
    /// #D3EB5C
    static let accent = Color(red: 0.827451, green: 0.921569, blue: 0.360784)
    static let accentHex = "#D3EB5C"
    /// #BFBAB0
    static let muted = Color(red: 0.749020, green: 0.729412, blue: 0.690196)
    static let mutedHex = "#BFBAB0"
    static let fontFamily = "Helvetica Neue"
}
