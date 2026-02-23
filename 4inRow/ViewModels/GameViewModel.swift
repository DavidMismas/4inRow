import SwiftUI
import Observation

/// Orchestrates game state, AI moves, animations, sound, and haptics.
@Observable
@MainActor
final class GameViewModel {

    // MARK: - Published State

    var board = Board()
    var gameState: GameState = .playing
    var currentPlayer: Player = .human
    var difficulty: Difficulty
    var theme: ColorTheme
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var stats: GameStats
    var isAIThinking = false
    var isDropAnimating = false

    /// Who starts each game: .human or .ai
    var firstPlayer: Player

    /// The board is interactive only after the user taps Play.
    var hasGameStarted = false

    /// Per-cell drop animation offsets in row-steps. Keyed by "col-row".
    var dropOffsets: [String: CGFloat] = [:]

    /// Cells that should animate (winning line highlight).
    var winningCells: [(col: Int, row: Int)] = []

    // MARK: - Private

    private let ai = AIEngine()
    private let storage = StorageService.shared
    private let haptic = HapticService.shared
    private let sound = SoundService.shared

    /// Reference to in-flight AI task so we can cancel on restart.
    private var aiTask: Task<Void, Never>?
    private var activeDropAnimations = 0
    private var gameRevision = 0

    private let dropAnimationResponse: TimeInterval = 0.42
    private let dropSettleDelay: TimeInterval = 0.5

    // MARK: - Init

    init() {
        difficulty = storage.difficulty
        theme = storage.theme
        soundEnabled = storage.soundEnabled
        hapticEnabled = storage.hapticEnabled
        stats = storage.stats
        firstPlayer = storage.firstPlayer
        currentPlayer = firstPlayer
    }

    // MARK: - Player Actions

    /// Human taps a column.
    func dropDisc(col: Int) {
        guard hasGameStarted else { return }

        guard canHumanDrop else {
            if hapticEnabled { haptic.invalidMove() }
            if soundEnabled { sound.playInvalid() }
            return
        }

        guard board.canDrop(col: col) else {
            if hapticEnabled { haptic.invalidMove() }
            if soundEnabled { sound.playInvalid() }
            return
        }

        performDrop(col: col, player: .human)
    }

    /// Restart the current game.
    func restart() {
        guard hasGameStarted else { return }

        resetBoardState()
    }

    /// Start a new game session from the idle state.
    func startGame() {
        hasGameStarted = true
        resetBoardState()
    }

    private func resetBoardState() {
        // Cancel any in-flight AI task
        aiTask?.cancel()
        aiTask = nil
        gameRevision += 1

        board = Board()
        gameState = .playing
        currentPlayer = firstPlayer
        isAIThinking = false
        isDropAnimating = false
        activeDropAnimations = 0
        dropOffsets = [:]
        winningCells = []

        // If AI starts, schedule its move
        if currentPlayer == .ai {
            scheduleAIMove()
        }
    }

    // MARK: - Settings

    func setDifficulty(_ d: Difficulty) {
        difficulty = d
        storage.difficulty = d
    }

    func setTheme(_ t: ColorTheme) {
        theme = t
        storage.theme = t
    }

    func setFirstPlayer(_ p: Player) {
        firstPlayer = p
        storage.firstPlayer = p
        if !hasGameStarted {
            currentPlayer = p
        }
    }

    func toggleSound() {
        soundEnabled.toggle()
        storage.soundEnabled = soundEnabled
    }

    func toggleHaptic() {
        hapticEnabled.toggle()
        storage.hapticEnabled = hapticEnabled
    }

    func resetStats() {
        stats.reset()
        storage.stats = stats
    }

    // MARK: - Core Game Flow

    private func performDrop(col: Int, player: Player) {
        guard let row = board.dropDisc(col: col, player: player) else { return }
        animateDrop(col: col, row: row)

        if hapticEnabled { haptic.discDrop() }
        if soundEnabled { sound.playDrop() }

        // Check game end
        if board.checkWin(player: player) {
            gameState = .win(player)
            winningCells = board.winningCells ?? []
            handleGameEnd()
            return
        }

        if board.isFull {
            gameState = .draw
            handleGameEnd()
            return
        }

        // Switch turn
        currentPlayer = player.opponent

        // If it's AI's turn, schedule the move
        if currentPlayer == .ai {
            scheduleAIMove()
        }
    }

    private func scheduleAIMove() {
        // Guard against double-scheduling
        guard !isAIThinking else { return }
        isAIThinking = true

        let boardCopy = board
        let diff = difficulty
        let revision = gameRevision

        // Run AI on background thread to keep UI responsive
        aiTask = Task.detached { [ai] in
            let col = ai.bestMove(board: boardCopy, difficulty: diff)

            // Small delay so the move feels natural
            try? await Task.sleep(for: .milliseconds(400))

            // Check cancellation before applying
            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.gameRevision == revision else { return }

                // Double-check game is still active and it's still AI's turn
                guard self.gameState == .playing,
                      self.currentPlayer == .ai,
                      self.isAIThinking else {
                    self.isAIThinking = false
                    return
                }

                self.isAIThinking = false
                self.performDrop(col: col, player: .ai)
            }
        }
    }

    private func handleGameEnd() {
        switch gameState {
        case .win(.human):
            stats.recordWin(difficulty)
            if hapticEnabled { haptic.win() }
            if soundEnabled { sound.playWin() }
        case .win(.ai):
            stats.recordLoss(difficulty)
            if hapticEnabled { haptic.lose() }
            if soundEnabled { sound.playLose() }
        case .draw:
            stats.recordDraw(difficulty)
            if soundEnabled { sound.playDraw() }
        case .playing:
            break
        }
        storage.stats = stats
    }

    // MARK: - View Helpers

    var canHumanDrop: Bool {
        hasGameStarted &&
        gameState == .playing &&
        currentPlayer == .human &&
        !isAIThinking &&
        !isDropAnimating
    }

    private func animateDrop(col: Int, row: Int) {
        let revision = gameRevision
        let key = "\(col)-\(row)"
        let rowsFromTop = CGFloat((Board.rows - 1) - row)

        activeDropAnimations += 1
        isDropAnimating = true
        dropOffsets[key] = -rowsFromTop

        // Defer to next run loop so the initial offset renders before we animate to zero.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.gameRevision == revision else { return }
            withAnimation(.interactiveSpring(response: self.dropAnimationResponse, dampingFraction: 0.72)) {
                self.dropOffsets[key] = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dropSettleDelay) { [weak self] in
            guard let self, self.gameRevision == revision else { return }
            // Fail-safe: if animation was interrupted, force the disc to its settled position.
            self.dropOffsets[key] = 0
            self.activeDropAnimations = max(0, self.activeDropAnimations - 1)
            self.isDropAnimating = self.activeDropAnimations > 0
        }
    }

    func colorForCell(col: Int, row: Int) -> Color {
        let val = board.cell(col: col, row: row)
        switch val {
        case Player.human.rawValue: return theme.humanColor
        case Player.ai.rawValue:    return theme.aiColor
        default:                    return theme.slotColor
        }
    }

    func gradientForCell(col: Int, row: Int) -> [Color] {
        let val = board.cell(col: col, row: row)
        switch val {
        case Player.human.rawValue: return theme.humanGradient
        case Player.ai.rawValue:    return theme.aiGradient
        default:                    return [theme.slotColor, theme.slotColor]
        }
    }

    func isWinningCell(col: Int, row: Int) -> Bool {
        winningCells.contains { $0.col == col && $0.row == row }
    }

    func dropOffset(col: Int, row: Int) -> CGFloat {
        dropOffsets["\(col)-\(row)"] ?? 0
    }

    var statusText: String {
        guard hasGameStarted else { return "Tap Play to start" }

        switch gameState {
        case .playing:
            if isAIThinking { return "Thinking..." }
            return currentPlayer == .human ? "Your turn" : "AI's turn"
        case .win(.human):
            return "You win!"
        case .win(.ai):
            return "AI wins!"
        case .draw:
            return "Draw!"
        }
    }

    var currentPlayerColor: Color {
        switch currentPlayer {
        case .human: return theme.humanColor
        case .ai:    return theme.aiColor
        }
    }
}
