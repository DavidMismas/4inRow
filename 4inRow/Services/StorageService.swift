import Foundation

/// Simple UserDefaults-backed persistence for settings and stats.
@MainActor
final class StorageService {

    static let shared = StorageService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let difficulty = "difficulty"
        static let theme = "theme"
        static let soundEnabled = "soundEnabled"
        static let hapticEnabled = "hapticEnabled"
        static let firstPlayer = "firstPlayer"
        static let stats = "stats"
    }

    private init() {}

    // MARK: - Settings

    var difficulty: Difficulty {
        get {
            guard let raw = defaults.string(forKey: Keys.difficulty),
                  let d = Difficulty(rawValue: raw) else { return .normal }
            return d
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.difficulty) }
    }

    var theme: ColorTheme {
        get {
            guard let raw = defaults.string(forKey: Keys.theme),
                  let t = ColorTheme(rawValue: raw) else { return .classic }
            return t
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.theme) }
    }

    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.soundEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    var hapticEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.hapticEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.hapticEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.hapticEnabled) }
    }

    var firstPlayer: Player {
        get {
            let raw = defaults.integer(forKey: Keys.firstPlayer)
            return Player(rawValue: raw) ?? .human
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.firstPlayer) }
    }

    // MARK: - Stats

    var stats: GameStats {
        get {
            guard let data = defaults.data(forKey: Keys.stats),
                  let s = try? JSONDecoder().decode(GameStats.self, from: data) else {
                return GameStats()
            }
            return s
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.stats)
            }
        }
    }
}
