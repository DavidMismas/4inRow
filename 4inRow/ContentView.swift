import SwiftUI

struct ContentView: View {
    @State private var vm = GameViewModel()

    var body: some View {
        GameView(vm: vm)
            .preferredColorScheme(vm.theme.isDark ? .dark : .light)
            .persistentSystemOverlays(.hidden)
    }
}
