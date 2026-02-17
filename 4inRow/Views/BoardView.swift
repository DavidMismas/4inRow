import SwiftUI

/// The game board grid with tap-to-drop interaction and drop animation.
struct BoardView: View {
    @Bindable var vm: GameViewModel

    private let spacing: CGFloat = 6
    private let slotPadding: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let boardWidth = geo.size.width
            let boardHeight = geo.size.height
            let slotSize = min(
                (boardWidth - spacing * CGFloat(Board.columns + 1)) / CGFloat(Board.columns),
                (boardHeight - spacing * CGFloat(Board.rows + 1)) / CGFloat(Board.rows)
            )
            let rowStep = slotSize + spacing
            let gridWidth = slotSize * CGFloat(Board.columns) + spacing * CGFloat(Board.columns + 1)
            let gridHeight = slotSize * CGFloat(Board.rows) + spacing * CGFloat(Board.rows + 1)

            ZStack {
                // Board background with gradient
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [vm.theme.boardGradientTop, vm.theme.boardColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: vm.theme.boardGlow, radius: 25)
                    .shadow(color: vm.theme.boardColor.opacity(0.5), radius: 8, y: 4)
                    .frame(width: gridWidth, height: gridHeight)

                // Subtle inner border
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .black.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: gridWidth, height: gridHeight)

                // Grid of slots
                VStack(spacing: spacing) {
                    ForEach((0..<Board.rows).reversed(), id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<Board.columns, id: \.self) { col in
                                let cellValue = vm.board.cell(col: col, row: row)
                                let currentDropOffset = vm.dropOffset(col: col, row: row)

                                ZStack {
                                    // Keep the slot visible even while a disc is animating above it.
                                    DiscView(
                                        color: vm.theme.slotColor,
                                        gradient: [vm.theme.slotColor, vm.theme.slotColor],
                                        isWinning: false,
                                        isEmpty: true,
                                        theme: vm.theme
                                    )

                                    if cellValue != 0 {
                                        DiscView(
                                            color: vm.colorForCell(col: col, row: row),
                                            gradient: vm.gradientForCell(col: col, row: row),
                                            isWinning: vm.isWinningCell(col: col, row: row),
                                            isEmpty: false,
                                            theme: vm.theme,
                                            showsNeonEffects: currentDropOffset == 0
                                        )
                                        .offset(y: currentDropOffset * rowStep)
                                    }
                                }
                                .frame(width: slotSize - slotPadding * 2,
                                       height: slotSize - slotPadding * 2)
                                .padding(slotPadding)
                            }
                        }
                    }
                }
                .padding(spacing)
                .frame(width: gridWidth, height: gridHeight)
                .clipped()

                // Invisible tap zones per column
                HStack(spacing: 0) {
                    ForEach(0..<Board.columns, id: \.self) { col in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.dropDisc(col: col)
                            }
                    }
                }
                .frame(width: gridWidth, height: gridHeight)
                .allowsHitTesting(vm.hasGameStarted)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
