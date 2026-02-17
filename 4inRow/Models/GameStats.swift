import Foundation

/// Persisted win/loss stats per difficulty level.
nonisolated struct GameStats: Codable, Sendable {
    var wins: [String: Int] = [:]
    var losses: [String: Int] = [:]
    var draws: [String: Int] = [:]

    func winsFor(_ difficulty: Difficulty) -> Int {
        wins[difficulty.rawValue] ?? 0
    }

    func lossesFor(_ difficulty: Difficulty) -> Int {
        losses[difficulty.rawValue] ?? 0
    }

    func drawsFor(_ difficulty: Difficulty) -> Int {
        draws[difficulty.rawValue] ?? 0
    }

    mutating func recordWin(_ difficulty: Difficulty) {
        wins[difficulty.rawValue, default: 0] += 1
    }

    mutating func recordLoss(_ difficulty: Difficulty) {
        losses[difficulty.rawValue, default: 0] += 1
    }

    mutating func recordDraw(_ difficulty: Difficulty) {
        draws[difficulty.rawValue, default: 0] += 1
    }

    mutating func reset() {
        wins = [:]
        losses = [:]
        draws = [:]
    }
}
