import Foundation

/// Connect Four AI engine.
/// Runs entirely on a background thread — safe to call from async contexts.
/// Supports four difficulty levels with distinct playing strategies.
/// Marked nonisolated to opt out of MainActor default isolation (pure computation, no UI).
nonisolated final class AIEngine: Sendable {

    // MARK: - Public API

    /// Choose the best column for the AI to play.
    /// This is the only method the rest of the app should call.
    /// - Parameters:
    ///   - board: Current board state (value type, safe to capture).
    ///   - difficulty: Desired AI strength.
    /// - Returns: The chosen column index.
    func bestMove(board: Board, difficulty: Difficulty) -> Int {
        let moves = board.validMoves
        guard !moves.isEmpty else { return 0 }
        guard moves.count > 1 else { return moves[0] }

        // For Easy/Normal: chance to make a random move (mistake)
        if difficulty.mistakeRate > 0 && Double.random(in: 0..<1) < difficulty.mistakeRate {
            return randomMove(board: board, difficulty: difficulty)
        }

        switch difficulty {
        case .easy:
            return easyMove(board: board)
        case .normal:
            return normalMove(board: board)
        case .hard, .expert:
            return minimaxMove(board: board, depth: difficulty.searchDepth)
        }
    }

    // MARK: - Easy AI

    /// Mostly random, but blocks immediate opponent wins.
    private func easyMove(board: Board) -> Int {
        let moves = board.validMoves

        // Block immediate human win
        if let block = findImmediateWin(board: board, player: .human) {
            return block
        }

        // Take immediate win if available
        if let win = findImmediateWin(board: board, player: .ai) {
            return win
        }

        // Otherwise random
        return moves.randomElement()!
    }

    // MARK: - Normal AI

    /// Looks 1-2 moves ahead, prefers center, uses basic heuristics.
    private func normalMove(board: Board) -> Int {
        let moves = board.validMoves

        // Take immediate win
        if let win = findImmediateWin(board: board, player: .ai) {
            return win
        }

        // Block immediate human win
        if let block = findImmediateWin(board: board, player: .human) {
            return block
        }

        // Look for setups: moves that create two-way wins
        if let setup = findSetupMove(board: board, player: .ai) {
            return setup
        }

        // Block opponent setups
        if let blockSetup = findSetupMove(board: board, player: .human) {
            return blockSetup
        }

        // Prefer center columns with some randomness
        let centerPreference = [3, 2, 4, 1, 5, 0, 6]
        let available = centerPreference.filter { moves.contains($0) }
        // Pick from top 3 center-biased choices
        let candidates = Array(available.prefix(3))
        return candidates.randomElement() ?? moves.randomElement()!
    }

    // MARK: - Random Move (for mistakes)

    /// Used when the AI deliberately makes a "mistake".
    /// For easy: fully random. For normal: avoids losing moves.
    private func randomMove(board: Board, difficulty: Difficulty) -> Int {
        let moves = board.validMoves

        if difficulty == .easy {
            return moves.randomElement()!
        }

        // For normal: pick random but avoid giving opponent an immediate win
        let safeMoves = moves.filter { col in
            var b = board
            b.dropDisc(col: col, player: .ai)
            return findImmediateWin(board: b, player: .human) == nil
        }

        return safeMoves.randomElement() ?? moves.randomElement()!
    }

    // MARK: - Minimax AI (Hard & Expert)

    /// Minimax with alpha-beta pruning and move ordering.
    private func minimaxMove(board: Board, depth: Int) -> Int {
        let moves = board.validMoves

        // Take immediate win
        if let win = findImmediateWin(board: board, player: .ai) {
            return win
        }

        // Block immediate human win
        if let block = findImmediateWin(board: board, player: .human) {
            return block
        }

        // Order moves: center columns first for better pruning
        let ordered = orderMoves(moves, board: board)

        var bestScore = Int.min
        var bestCol = ordered[0]

        var alpha = Int.min
        let beta = Int.max

        for col in ordered {
            var b = board
            b.dropDisc(col: col, player: .ai)

            // Minimax returns score from AI's perspective
            let score = minimax(
                board: b,
                depth: depth - 1,
                alpha: alpha,
                beta: beta,
                isMaximizing: false  // Next turn is human (minimizing)
            )

            if score > bestScore {
                bestScore = score
                bestCol = col
            }
            alpha = max(alpha, score)
        }

        return bestCol
    }

    /// Recursive minimax with alpha-beta pruning.
    /// - isMaximizing: true when it's AI's turn, false for human.
    /// - Returns: heuristic score (positive = good for AI).
    private func minimax(
        board: Board,
        depth: Int,
        alpha: Int,
        beta: Int,
        isMaximizing: Bool
    ) -> Int {
        // Terminal checks
        if board.hasWon(player: .ai)    { return 100000 + depth }  // Win sooner = better
        if board.hasWon(player: .human) { return -100000 - depth } // Lose later = better
        if board.isFull                 { return 0 }               // Draw
        if depth == 0                   { return board.evaluate(for: .ai) }

        let moves = orderMoves(board.validMoves, board: board)
        var alpha = alpha
        var beta = beta

        if isMaximizing {
            var maxScore = Int.min
            for col in moves {
                var b = board
                b.dropDisc(col: col, player: .ai)
                let score = minimax(board: b, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: false)
                maxScore = max(maxScore, score)
                alpha = max(alpha, score)
                if beta <= alpha { break }  // Beta cutoff
            }
            return maxScore
        } else {
            var minScore = Int.max
            for col in moves {
                var b = board
                b.dropDisc(col: col, player: .human)
                let score = minimax(board: b, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: true)
                minScore = min(minScore, score)
                beta = min(beta, score)
                if beta <= alpha { break }  // Alpha cutoff
            }
            return minScore
        }
    }

    // MARK: - Helpers

    /// Find a column that gives `player` an immediate win.
    private func findImmediateWin(board: Board, player: Player) -> Int? {
        for col in board.validMoves {
            var b = board
            b.dropDisc(col: col, player: player)
            if b.hasWon(player: player) { return col }
        }
        return nil
    }

    /// Find a move that creates a "fork" — two separate threats.
    /// Used by Normal AI for basic tactical awareness.
    private func findSetupMove(board: Board, player: Player) -> Int? {
        for col in board.validMoves {
            var b = board
            b.dropDisc(col: col, player: player)

            // Count how many winning moves would exist after this move
            var threats = 0
            for nextCol in b.validMoves {
                var b2 = b
                b2.dropDisc(col: nextCol, player: player)
                if b2.hasWon(player: player) {
                    threats += 1
                }
            }
            if threats >= 2 { return col }
        }
        return nil
    }

    /// Order moves so center columns are searched first.
    /// This dramatically improves alpha-beta pruning efficiency.
    private func orderMoves(_ moves: [Int], board: Board) -> [Int] {
        let center = Board.columns / 2
        return moves.sorted { a, b in
            abs(a - center) < abs(b - center)
        }
    }
}
