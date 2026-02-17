import Foundation

/// AI difficulty levels with associated search depths.
nonisolated enum Difficulty: String, CaseIterable, Codable, Hashable, Sendable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    case expert = "Expert"

    /// Minimax search depth for this difficulty.
    var searchDepth: Int {
        switch self {
        case .easy:   return 1
        case .normal: return 3
        case .hard:   return 7
        case .expert: return 10
        }
    }

    /// Probability of making a random (suboptimal) move.
    var mistakeRate: Double {
        switch self {
        case .easy:   return 0.5
        case .normal: return 0.15
        case .hard:   return 0.03
        case .expert: return 0.0
        }
    }

    var emoji: String {
        switch self {
        case .easy:   return "🟢"
        case .normal: return "🟡"
        case .hard:   return "🟠"
        case .expert: return "🔴"
        }
    }
}
