import SwiftUI

/// Settings overlay: theme, sound, haptics.
struct SettingsSheet: View {
    @Bindable var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Theme
                Section("Theme") {
                    ForEach(ColorTheme.allCases, id: \.rawValue) { theme in
                        Button {
                            vm.setTheme(theme)
                        } label: {
                            HStack {
                                Circle().fill(theme.humanColor).frame(width: 20, height: 20)
                                Circle().fill(theme.aiColor).frame(width: 20, height: 20)
                                Circle().fill(theme.boardColor).frame(width: 20, height: 20)
                                Text(theme.rawValue)
                                    .foregroundStyle(vm.theme == theme ? .primary : .secondary)
                                Spacer()
                                if vm.theme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }

                // Sound & Haptics
                Section("Feedback") {
                    Toggle("Sound Effects", isOn: Binding(
                        get: { vm.soundEnabled },
                        set: { _ in vm.toggleSound() }
                    ))
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { vm.hapticEnabled },
                        set: { _ in vm.toggleHaptic() }
                    ))
                }

                // Stats
                Section("Statistics") {
                    ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                        HStack {
                            Text("\(diff.emoji) \(diff.rawValue)")
                            Spacer()
                            Text("W:\(vm.stats.winsFor(diff))")
                                .foregroundStyle(.green)
                            Text("L:\(vm.stats.lossesFor(diff))")
                                .foregroundStyle(.red)
                            Text("D:\(vm.stats.drawsFor(diff))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.system(.body, design: .monospaced))
                    }

                    Button("Reset Stats", role: .destructive) {
                        vm.resetStats()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
