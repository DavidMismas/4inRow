import Foundation

/// Connect Four board: 7 columns × 6 rows.
/// Uses a flat array internally for fast AI evaluation.
/// Column 0 is leftmost, row 0 is bottom.
nonisolated struct Board: Sendable {
    static let columns = 7
    static let rows = 6
    static let winLength = 4

    /// Flat grid storage: grid[col * rows + row]. 0 = empty, 1 = human, 2 = ai.
    private(set) var grid: [Int]

    /// Number of discs in each column (acts as the "height" pointer).
    private(set) var heights: [Int]

    /// Total number of moves played.
    private(set) var moveCount: Int

    /// The cells forming the winning line, if any (for highlighting).
    private(set) var winningCells: [(col: Int, row: Int)]?

    init() {
        grid = Array(repeating: 0, count: Board.columns * Board.rows)
        heights = Array(repeating: 0, count: Board.columns)
        moveCount = 0
        winningCells = nil
    }

    // MARK: - Grid Access

    /// Get the value at (col, row). Returns 0, 1, or 2.
    func cell(col: Int, row: Int) -> Int {
        grid[col * Board.rows + row]
    }

    /// Check if a column can accept another disc.
    func canDrop(col: Int) -> Bool {
        col >= 0 && col < Board.columns && heights[col] < Board.rows
    }

    /// All columns that can still accept a disc.
    var validMoves: [Int] {
        (0..<Board.columns).filter { canDrop(col: $0) }
    }

    /// Whether the board is completely full.
    var isFull: Bool {
        moveCount >= Board.columns * Board.rows
    }

    // MARK: - Drop Disc

    /// Drop a disc into `col` for `player`. Returns the row it lands on, or nil if invalid.
    @discardableResult
    mutating func dropDisc(col: Int, player: Player) -> Int? {
        guard canDrop(col: col) else { return nil }
        let row = heights[col]
        grid[col * Board.rows + row] = player.rawValue
        heights[col] += 1
        moveCount += 1
        return row
    }

    /// Undo the last disc in `col`. Used by AI during search.
    mutating func undoDrop(col: Int) {
        guard heights[col] > 0 else { return }
        heights[col] -= 1
        let row = heights[col]
        grid[col * Board.rows + row] = 0
        moveCount -= 1
    }

    // MARK: - Win Detection

    /// Check if `player` has won. If so, records the winning cells.
    mutating func checkWin(player: Player) -> Bool {
        let p = player.rawValue

        // Direction vectors: horizontal, vertical, diagonal /, diagonal \
        let directions: [(dc: Int, dr: Int)] = [(1, 0), (0, 1), (1, 1), (1, -1)]

        for col in 0..<Board.columns {
            for row in 0..<Board.rows {
                guard cell(col: col, row: row) == p else { continue }

                for dir in directions {
                    var cells = [(col: Int, row: Int)]()
                    cells.append((col, row))
                    var valid = true

                    for step in 1..<Board.winLength {
                        let c = col + dir.dc * step
                        let r = row + dir.dr * step
                        guard c >= 0, c < Board.columns,
                              r >= 0, r < Board.rows,
                              cell(col: c, row: r) == p else {
                            valid = false
                            break
                        }
                        cells.append((c, r))
                    }

                    if valid {
                        winningCells = cells
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Non-mutating win check (doesn't store winning cells). Used by AI.
    func hasWon(player: Player) -> Bool {
        let p = player.rawValue
        let directions: [(dc: Int, dr: Int)] = [(1, 0), (0, 1), (1, 1), (1, -1)]

        for col in 0..<Board.columns {
            for row in 0..<Board.rows {
                guard cell(col: col, row: row) == p else { continue }

                for dir in directions {
                    var count = 1
                    for step in 1..<Board.winLength {
                        let c = col + dir.dc * step
                        let r = row + dir.dr * step
                        guard c >= 0, c < Board.columns,
                              r >= 0, r < Board.rows,
                              cell(col: c, row: r) == p else { break }
                        count += 1
                    }
                    if count >= Board.winLength { return true }
                }
            }
        }
        return false
    }

    // MARK: - Board Evaluation (for AI heuristics)

    /// Score the board from `player`'s perspective.
    /// Positive = favorable, negative = unfavorable.
    func evaluate(for player: Player) -> Int {
        let opp = player.opponent
        var score = 0

        // Bonus for center column control
        let centerCol = Board.columns / 2
        for row in 0..<Board.rows {
            if cell(col: centerCol, row: row) == player.rawValue {
                score += 3
            }
        }

        // Scan all windows of 4
        let directions: [(dc: Int, dr: Int)] = [(1, 0), (0, 1), (1, 1), (1, -1)]

        for col in 0..<Board.columns {
            for row in 0..<Board.rows {
                for dir in directions {
                    // Collect the 4-cell window
                    var mine = 0
                    var theirs = 0
                    var empty = 0
                    var valid = true

                    for step in 0..<Board.winLength {
                        let c = col + dir.dc * step
                        let r = row + dir.dr * step
                        guard c >= 0, c < Board.columns,
                              r >= 0, r < Board.rows else {
                            valid = false
                            break
                        }
                        let val = cell(col: c, row: r)
                        if val == player.rawValue { mine += 1 }
                        else if val == opp.rawValue { theirs += 1 }
                        else { empty += 1 }
                    }

                    guard valid else { continue }

                    // Score windows: only count if not blocked by opponent
                    if theirs == 0 {
                        switch mine {
                        case 4: score += 10000
                        case 3: score += 50
                        case 2: score += 10
                        default: break
                        }
                    }
                    if mine == 0 {
                        switch theirs {
                        case 4: score -= 10000
                        case 3: score -= 50
                        case 2: score -= 10
                        default: break
                        }
                    }
                }
            }
        }

        return score
    }
}
