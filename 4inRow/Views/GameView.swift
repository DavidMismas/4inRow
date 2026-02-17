import SwiftUI

/// Main game screen with orientation-aware layout and a Play-to-start flow.
struct GameView: View {
    private struct GameOverCopy {
        let title: String
        let subtitle: String
        let icon: String
    }

    @Bindable var vm: GameViewModel
    @State private var showSettings = false
    @State private var showGameOver = false
    @State private var gameOverCopy = GameOverCopy(title: "", subtitle: "", icon: "flag.fill")
    @State private var gameOverCardScale: CGFloat = 0.86
    @State private var gameOverIconScale: CGFloat = 0.8
    @State private var gameOverGlowOpacity: Double = 0.35
    @State private var gameOverShakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            vm.theme.backgroundColor.ignoresSafeArea()

            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height

                ZStack {
                    if isLandscape {
                        landscapeLayout(geo: geo)
                    } else {
                        portraitLayout(geo: geo)
                    }

                    if showGameOver {
                        gameOverOverlay
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: vm.theme)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(vm: vm)
        }
        .onChange(of: vm.gameState) { _, newState in
            guard vm.hasGameStarted else {
                resetGameOverAnimationState()
                showGameOver = false
                return
            }

            if newState.isOver {
                gameOverCopy = gameOverCopy(for: newState)
                resetGameOverAnimationState()
                withAnimation(.easeInOut(duration: 0.3).delay(0.6)) {
                    showGameOver = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
                    animateGameOver(for: newState)
                }
            }
        }
    }

    // MARK: - Landscape

    @ViewBuilder
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 8
        let minPanelWidth: CGFloat = 160
        let sideVerticalOffset: CGFloat = 22
        let leftHorizontalOffset: CGFloat = -20
        let rightHorizontalOffset: CGFloat = 20
        let boardAspect = CGFloat(Board.columns) / CGFloat(Board.rows)
        let boardHeight = geo.size.height - verticalPadding * 2
        let boardWidth = boardHeight * boardAspect
        let computedSideWidth = (geo.size.width - boardWidth) / 2 - horizontalPadding
        let sideWidth = max(computedSideWidth, minPanelWidth)

        ZStack {
            BoardView(vm: vm)
                .frame(width: boardWidth, height: boardHeight)

            HStack(spacing: 0) {
                leftLandscapePanel
                    .frame(width: sideWidth, alignment: .leading)
                    .offset(x: leftHorizontalOffset, y: sideVerticalOffset)

                Spacer(minLength: 0)

                rightLandscapePanel
                    .frame(width: sideWidth, alignment: .trailing)
                    .offset(x: rightHorizontalOffset, y: sideVerticalOffset)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Portrait

    @ViewBuilder
    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            controlsPanel()
                .padding(.horizontal, 16)

            boardContainer(geo: geo)
                .padding(.bottom, 6)
        }
    }

    // MARK: - Shared Layout

    private var topBar: some View {
        HStack(alignment: .center) {
            statusView
            Spacer(minLength: 8)

            HStack(spacing: 10) {
                smallActionButton(icon: "arrow.counterclockwise", isEnabled: vm.hasGameStarted) {
                    vm.restart()
                    showGameOver = false
                }

                smallActionButton(icon: "gearshape.fill", isEnabled: true) {
                    showSettings = true
                }
            }
        }
    }

    private var leftLandscapePanel: some View {
        VStack(spacing: 12) {
            landscapeCard {
                statusView
            }

            landscapeCard {
                Text("First")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(vm.theme.textColor)
                    .lineLimit(1)

                firstPlayerLandscapePicker
            }

            landscapeActionButton(
                icon: "arrow.counterclockwise",
                label: "Restart",
                isEnabled: vm.hasGameStarted
            ) {
                vm.restart()
                showGameOver = false
            }

            landscapeActionButton(
                icon: "gearshape.fill",
                label: "Settings",
                isEnabled: true
            ) {
                showSettings = true
            }

            Spacer(minLength: 0)
        }
    }

    private var rightLandscapePanel: some View {
        VStack(spacing: 12) {
            landscapeCard {
                Text("Difficulty")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(vm.theme.textColor)
                    .lineLimit(1)

                difficultyPicker
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            playButton

            Spacer(minLength: 0)
        }
    }

    private func controlsPanel() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("Difficulty")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(vm.theme.textColor)

                Spacer()

                difficultyPicker
            }

            firstPlayerPicker
            playButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(vm.theme.buttonColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var difficultyPicker: some View {
        Picker("Difficulty", selection: Binding(
            get: { vm.difficulty },
            set: { diff in
                vm.setDifficulty(diff)
                if vm.hasGameStarted {
                    vm.restart()
                    showGameOver = false
                }
            }
        )) {
            ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                Text(diff.rawValue).tag(diff)
            }
        }
        .pickerStyle(.menu)
        .tint(vm.theme.textColor)
    }

    private var firstPlayerPicker: some View {
        Picker("First Player", selection: Binding(
            get: { vm.firstPlayer },
            set: { player in
                vm.setFirstPlayer(player)
                if vm.hasGameStarted {
                    vm.startGame()
                    showGameOver = false
                }
            }
        )) {
            Label("You First", systemImage: "person.fill")
                .tag(Player.human)
            Label("AI First", systemImage: "cpu")
                .tag(Player.ai)
        }
        .pickerStyle(.segmented)
    }

    private var firstPlayerLandscapePicker: some View {
        Picker("First Player", selection: Binding(
            get: { vm.firstPlayer },
            set: { player in
                vm.setFirstPlayer(player)
                if vm.hasGameStarted {
                    vm.startGame()
                    showGameOver = false
                }
            }
        )) {
            Text("You First").tag(Player.human)
            Text("AI First").tag(Player.ai)
        }
        .pickerStyle(.menu)
        .tint(vm.theme.textColor)
    }

    private var playButton: some View {
        Button {
            if vm.hasGameStarted {
                vm.restart()
            } else {
                vm.startGame()
            }
            showGameOver = false
        } label: {
            Label(
                vm.hasGameStarted ? "Restart" : "Play",
                systemImage: vm.hasGameStarted ? "arrow.counterclockwise" : "play.fill"
            )
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: vm.theme.accentGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: vm.theme.accentColor.opacity(0.45), radius: 10, y: 3)
                )
        }
        .buttonStyle(BounceButtonStyle())
    }

    @ViewBuilder
    private func boardContainer(geo: GeometryProxy) -> some View {
        let boardAspect = CGFloat(Board.columns) / CGFloat(Board.rows)
        let maxBoardWidth = geo.size.width - 12
        let maxBoardHeight = geo.size.height * 0.66
        let boardWidth = min(maxBoardWidth, maxBoardHeight * boardAspect)
        let boardHeight = boardWidth / boardAspect

        HStack {
            Spacer(minLength: 0)
            BoardView(vm: vm)
                .frame(width: boardWidth, height: boardHeight)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func landscapeCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(vm.theme.buttonColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Status

    private var statusView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [vm.currentPlayerColor.opacity(0.9), vm.currentPlayerColor],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)
                .shadow(color: vm.currentPlayerColor.opacity(0.6), radius: 10)
                .animation(.easeInOut(duration: 0.3), value: vm.currentPlayer)

            Text(vm.statusText)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(vm.theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: vm.statusText)

            if vm.isAIThinking {
                ProgressView()
                    .scaleEffect(0.9)
                    .tint(vm.theme.secondaryTextColor)
            }
        }
    }

    // MARK: - Small Action Buttons

    private func landscapeActionButton(
        icon: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isEnabled ? vm.theme.textColor : vm.theme.secondaryTextColor.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(vm.theme.buttonColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BounceButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }

    private func smallActionButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isEnabled ? vm.theme.textColor : vm.theme.secondaryTextColor.opacity(0.55))
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(vm.theme.buttonColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(BounceButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    resetGameOverAnimationState()
                    withAnimation { showGameOver = false }
                }

            VStack(spacing: 20) {
                Image(systemName: displayedGameOverCopy.icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(gameOverColor)
                    .scaleEffect(gameOverIconScale)
                    .shadow(color: gameOverColor.opacity(gameOverGlowOpacity), radius: 16)

                Text(displayedGameOverCopy.title)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(gameOverColor)
                    .multilineTextAlignment(.center)

                Text(displayedGameOverCopy.subtitle)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Button {
                    vm.startGame()
                    resetGameOverAnimationState()
                    withAnimation { showGameOver = false }
                } label: {
                    Text("Play Again")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: vm.theme.accentGradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: vm.theme.accentColor.opacity(0.5), radius: 12, y: 4)
                        )
                }
                .buttonStyle(BounceButtonStyle())
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 30)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(gameOverColor.opacity(gameOverGlowOpacity), lineWidth: 2)
            )
            .scaleEffect(gameOverCardScale)
            .offset(x: gameOverShakeOffset)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    private var displayedGameOverCopy: GameOverCopy {
        if gameOverCopy.title.isEmpty || gameOverCopy.subtitle.isEmpty {
            return fallbackGameOverCopy(for: vm.gameState)
        }
        return gameOverCopy
    }

    private func gameOverCopy(for state: GameState) -> GameOverCopy {
        switch state {
        case .win(.human):
            let options = [
                GameOverCopy(
                    title: "Nice win!",
                    subtitle: "Great reads and timing. You took this one.",
                    icon: "party.popper.fill"
                ),
                GameOverCopy(
                    title: "Well played!",
                    subtitle: "You kept control and closed it out.",
                    icon: "hands.clap.fill"
                ),
                GameOverCopy(
                    title: "That was clean!",
                    subtitle: "Solid game. Want another round?",
                    icon: "sparkles"
                )
            ]
            return options.randomElement() ?? options[0]

        case .win(.ai):
            let options = [
                GameOverCopy(
                    title: "Good fight.",
                    subtitle: "This round slipped away. You can take the next one.",
                    icon: "tortoise.fill"
                ),
                GameOverCopy(
                    title: "So close!",
                    subtitle: "You had chances. One more game?",
                    icon: "bolt.horizontal.circle"
                ),
                GameOverCopy(
                    title: "Tough round.",
                    subtitle: "No worries, reset and try a different line.",
                    icon: "arrow.trianglehead.counterclockwise"
                )
            ]
            return options.randomElement() ?? options[0]

        case .draw:
            let options = [
                GameOverCopy(
                    title: "That was tight.",
                    subtitle: "Even board. Nobody blinked.",
                    icon: "equal.circle.fill"
                ),
                GameOverCopy(
                    title: "Dead even.",
                    subtitle: "A draw. Run it back?",
                    icon: "pause.circle.fill"
                ),
                GameOverCopy(
                    title: "No winner this time.",
                    subtitle: "You matched the AI move for move.",
                    icon: "square.split.2x2.fill"
                )
            ]
            return options.randomElement() ?? options[0]

        case .playing:
            return GameOverCopy(title: "Game Over", subtitle: "Play again when you're ready.", icon: "flag.fill")
        }
    }

    private func fallbackGameOverCopy(for state: GameState) -> GameOverCopy {
        switch state {
        case .win(.human):
            return GameOverCopy(
                title: "You won!",
                subtitle: "Nice work. Want another round?",
                icon: "sparkles"
            )
        case .win(.ai):
            return GameOverCopy(
                title: "Close one.",
                subtitle: "Reset and try a different line.",
                icon: "arrow.trianglehead.counterclockwise"
            )
        case .draw:
            return GameOverCopy(
                title: "Draw.",
                subtitle: "That one was evenly matched.",
                icon: "equal.circle.fill"
            )
        case .playing:
            return GameOverCopy(
                title: "Game Over",
                subtitle: "Play again when you're ready.",
                icon: "flag.fill"
            )
        }
    }

    private func resetGameOverAnimationState() {
        gameOverCardScale = 0.86
        gameOverIconScale = 0.8
        gameOverGlowOpacity = 0.35
        gameOverShakeOffset = 0
    }

    private func animateGameOver(for state: GameState) {
        switch state {
        case .win(.human):
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                gameOverCardScale = 1.0
                gameOverIconScale = 1.08
                gameOverGlowOpacity = 0.95
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                gameOverCardScale = 1.02
                gameOverIconScale = 1.15
                gameOverGlowOpacity = 0.6
            }

        case .win(.ai):
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                gameOverCardScale = 1.0
                gameOverIconScale = 1.0
                gameOverGlowOpacity = 0.75
            }
            withAnimation(.easeInOut(duration: 0.08).repeatCount(4, autoreverses: true)) {
                gameOverShakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                gameOverShakeOffset = 0
            }

        case .draw:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                gameOverCardScale = 1.0
                gameOverIconScale = 1.0
                gameOverGlowOpacity = 0.65
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                gameOverCardScale = 1.01
            }

        case .playing:
            break
        }
    }

    private var gameOverColor: Color {
        switch vm.gameState {
        case .win(.human): return .green
        case .win(.ai):    return .red
        case .draw:        return .orange
        case .playing:     return .white
        }
    }
}

// MARK: - Bounce Button Style

/// Adds a scale-down press animation to any button.
private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
