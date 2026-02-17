import Foundation

/// Current state of the game.
nonisolated enum GameState: Equatable, Sendable {
    case playing
    case win(Player)
    case draw

    var isOver: Bool {
        self != .playing
    }
}
