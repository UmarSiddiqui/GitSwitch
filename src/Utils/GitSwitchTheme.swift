import SwiftUI

/// Shared colors, radii, and chrome for GitSwitch (menu bar + settings).
enum GitSwitchTheme {
    static let brandIndigo = Color(red: 0.22, green: 0.32, blue: 0.84)

    static let cornerPanel: CGFloat = 14
    static let cornerCard: CGFloat = 12
    static let cornerRow: CGFloat = 10
    static let minMenuWidth: CGFloat = 296

    static let brandTileGradient = LinearGradient(
        colors: [
            brandIndigo.opacity(0.95),
            brandIndigo.opacity(0.65),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func sectionCaption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

/// App mark used in menu bar and settings header.
struct GitSwitchBrandTile: View {
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .fill(GitSwitchTheme.brandTileGradient)
                .frame(width: size, height: size)
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
