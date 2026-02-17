import UIKit

/// Provides haptic feedback throughout the game.
@MainActor
final class HapticService {

    static let shared = HapticService()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        lightGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// Light tap — disc drop.
    func discDrop() {
        lightGenerator.impactOccurred()
    }

    /// Strong impact — win.
    func win() {
        heavyGenerator.impactOccurred()
    }

    /// Medium impact — lose.
    func lose() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error vibration — invalid move.
    func invalidMove() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// Soft tap — UI interaction.
    func tap() {
        lightGenerator.impactOccurred(intensity: 0.5)
    }
}
