import SwiftUI

// Calm Signal design tokens extracted from the approved Claude Design prototype.
enum HarborColors {
    static let calmTeal = Color(hex: 0x087F78)
    static let deepTeal = Color(hex: 0x066B66)
    static let seaGlass = Color(hex: 0xD9F1EE)
    static let clearSky = Color(hex: 0x5B8DEF)
    static let softCoral = Color(hex: 0xF2766B)
    static let safeGreen = Color(hex: 0x32A873)
    static let warmAmber = Color(hex: 0xE7A53B)
    static let signalRed = Color(hex: 0xD94B50)
    static let oceanInk = Color(hex: 0x17252D)
    static let slate = Color(hex: 0x65747C)
    static let morningMist = Color(hex: 0xF4F7F6)
    static let cloudWhite = Color(hex: 0xFCFDFD)
    static let mineralBorder = Color(hex: 0xDCE5E3)
    static let nightOcean = Color(hex: 0x0B151A)
    static let deepSlate = Color(hex: 0x142329)

    static let brandGradient = LinearGradient(
        colors: [calmTeal, clearSky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum HarborSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let standard: CGFloat = 20
    static let section: CGFloat = 28
}

enum HarborRadius {
    static let field: CGFloat = 16
    static let card: CGFloat = 20
    static let sheet: CGFloat = 30
    static let pill: CGFloat = 999
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct HarborCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(colorScheme == .dark ? HarborColors.deepSlate : .white)
            .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous)
                    .stroke(HarborColors.mineralBorder.opacity(colorScheme == .dark ? 0.16 : 0.8), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.07), radius: 16, y: 4)
    }
}

extension View {
    func harborCard() -> some View {
        modifier(HarborCardModifier())
    }
}
