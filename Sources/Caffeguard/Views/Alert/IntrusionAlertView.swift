import SwiftUI

/// The full-screen intrusion message, drawn in a theme over an optional wallpaper.
struct IntrusionAlertView: View {
    let configuration: IntrusionScreenConfiguration
    var wallpaper: NSImage?

    private var theme: Theme { configuration.theme }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: theme.symbol)
                .font(.system(size: 128))
                .foregroundStyle(theme.accent)
            Text(theme.title)
                .font(theme.titleFont(64))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            Text(verbatim: configuration.displayMessage)
                .font(theme.bodyFont(28))
                .lineLimit(8)
                .minimumScaleFactor(0.5)
            Label(configuration.unlockTrigger.instruction, systemImage: "lock.shield")
                .font(theme.bodyFont(18))
                .opacity(0.7)
                .padding(.top, 24)
        }
        .foregroundStyle(theme.foreground)
        .multilineTextAlignment(.center)
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background }
    }

    @ViewBuilder private var background: some View {
        let gradient = LinearGradient(colors: theme.colors, startPoint: .top, endPoint: .bottom)
        if let wallpaper {
            Image(nsImage: wallpaper)
                .resizable()
                .scaledToFill()
                // A wash of the theme's colors keeps its text readable on any picture.
                .overlay(gradient.opacity(0.6))
                .clipped()
        } else {
            gradient
        }
    }
}
