import SwiftUI

/// A single disc/slot on the board with gradient fills and glow effects.
struct DiscView: View {
    let color: Color
    let gradient: [Color]
    let isWinning: Bool
    let isEmpty: Bool
    let theme: ColorTheme
    let showsNeonEffects: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0

    init(
        color: Color,
        gradient: [Color],
        isWinning: Bool,
        isEmpty: Bool,
        theme: ColorTheme,
        showsNeonEffects: Bool = true
    ) {
        self.color = color
        self.gradient = gradient
        self.isWinning = isWinning
        self.isEmpty = isEmpty
        self.theme = theme
        self.showsNeonEffects = showsNeonEffects
    }

    var body: some View {
        ZStack {
            if isEmpty {
                // Empty slot — subtle inset look
                Circle()
                    .fill(theme.slotColor)
                    .overlay {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.04), .clear],
                                    center: .top,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )
                    }
            } else {
                // Glow behind disc (for neon theme especially)
                if theme == .neon && showsNeonEffects {
                    Circle()
                        .fill(color.opacity(0.35))
                        .blur(radius: 10)
                        .scaleEffect(1.3)
                }

                // Disc with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        // Glossy highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.45), .white.opacity(0.1), .clear],
                                    center: UnitPoint(x: 0.35, y: 0.25),
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .padding(3)
                    }
                    .overlay {
                        // Rim shadow
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear, .black.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(
                        color: showsNeonEffects ? color.opacity(theme == .neon ? 0.5 : 0.3) : .clear,
                        radius: showsNeonEffects ? 6 : 0,
                        y: 2
                    )

                // Winning ring pulse
                if isWinning {
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 3)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - Double(pulseScale))
                }
            }
        }
        .scaleEffect(isWinning ? pulseScale : 1.0)
        .onAppear {
            if isWinning {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.12
                }
            }
        }
    }
}
