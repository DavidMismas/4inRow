import Foundation

/// Represents a disc on the board or the current player.
nonisolated enum Player: Int, Hashable, Sendable {
    case human = 1
    case ai = 2

    var opponent: Player {
        self == .human ? .ai : .human
    }
}
