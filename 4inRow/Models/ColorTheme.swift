import SwiftUI

/// Visual color themes for the game.
enum ColorTheme: String, CaseIterable, Codable, Sendable {
    case classic = "Classic"
    case neon = "Neon"
    case minimal = "Minimal Dark"

    // MARK: - Disc Colors

    var humanColor: Color {
        switch self {
        case .classic: return Color(red: 0.92, green: 0.18, blue: 0.18)
        case .neon:    return Color(red: 1.0, green: 0.1, blue: 0.5)
        case .minimal: return Color(red: 0.95, green: 0.95, blue: 1.0)
        }
    }

    var humanGradient: [Color] {
        switch self {
        case .classic: return [Color(red: 1.0, green: 0.35, blue: 0.3), Color(red: 0.75, green: 0.1, blue: 0.1)]
        case .neon:    return [Color(red: 1.0, green: 0.4, blue: 0.7), Color(red: 0.9, green: 0.0, blue: 0.35)]
        case .minimal: return [Color(red: 1.0, green: 1.0, blue: 1.0), Color(red: 0.82, green: 0.82, blue: 0.9)]
        }
    }

    var aiColor: Color {
        switch self {
        case .classic: return Color(red: 1.0, green: 0.82, blue: 0.0)
        case .neon:    return Color(red: 0.0, green: 1.0, blue: 0.8)
        case .minimal: return Color(red: 0.55, green: 0.25, blue: 0.85)
        }
    }

    var aiGradient: [Color] {
        switch self {
        case .classic: return [Color(red: 1.0, green: 0.92, blue: 0.3), Color(red: 0.9, green: 0.65, blue: 0.0)]
        case .neon:    return [Color(red: 0.3, green: 1.0, blue: 0.9), Color(red: 0.0, green: 0.75, blue: 0.6)]
        case .minimal: return [Color(red: 0.7, green: 0.4, blue: 1.0), Color(red: 0.4, green: 0.15, blue: 0.7)]
        }
    }

    // MARK: - Board

    var boardColor: Color {
        switch self {
        case .classic: return Color(red: 0.12, green: 0.2, blue: 0.56)
        case .neon:    return Color(red: 0.1, green: 0.1, blue: 0.22)
        case .minimal: return Color(red: 0.12, green: 0.12, blue: 0.15)
        }
    }

    var boardGradientTop: Color {
        switch self {
        case .classic: return Color(red: 0.72, green: 0.64, blue: 0.9)
        case .neon:    return Color(red: 0.14, green: 0.12, blue: 0.3)
        case .minimal: return Color(red: 0.15, green: 0.15, blue: 0.18)
        }
    }

    var slotColor: Color {
        switch self {
        case .classic: return Color(red: 0.08, green: 0.13, blue: 0.35)
        case .neon:    return Color(red: 0.06, green: 0.06, blue: 0.14)
        case .minimal: return Color(red: 0.07, green: 0.07, blue: 0.09)
        }
    }

    // MARK: - Background

    var backgroundColor: Color {
        switch self {
        case .classic: return Color(red: 0.85, green: 0.91, blue: 0.98)
        case .neon:    return Color(red: 0.04, green: 0.04, blue: 0.1)
        case .minimal: return Color(red: 0.06, green: 0.06, blue: 0.08)
        }
    }

    // MARK: - Text

    var textColor: Color {
        switch self {
        case .classic: return Color(red: 0.12, green: 0.12, blue: 0.22)
        case .neon:    return .white
        case .minimal: return Color(red: 0.82, green: 0.82, blue: 0.85)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .classic: return Color(red: 0.35, green: 0.35, blue: 0.5)
        case .neon:    return Color(red: 0.6, green: 0.6, blue: 0.75)
        case .minimal: return Color(red: 0.5, green: 0.5, blue: 0.55)
        }
    }

    // MARK: - UI Elements

    var accentColor: Color {
        switch self {
        case .classic: return Color(red: 0.2, green: 0.45, blue: 0.88)
        case .neon:    return Color(red: 0.55, green: 0.2, blue: 1.0)
        case .minimal: return Color(red: 0.55, green: 0.25, blue: 0.85)
        }
    }

    var accentGradient: [Color] {
        switch self {
        case .classic: return [Color(red: 0.3, green: 0.55, blue: 0.95), Color(red: 0.15, green: 0.35, blue: 0.78)]
        case .neon:    return [Color(red: 0.7, green: 0.3, blue: 1.0), Color(red: 0.4, green: 0.1, blue: 0.85)]
        case .minimal: return [Color(red: 0.65, green: 0.35, blue: 0.95), Color(red: 0.45, green: 0.15, blue: 0.75)]
        }
    }

    var buttonColor: Color {
        switch self {
        case .classic: return Color(red: 0.75, green: 0.82, blue: 0.94)
        case .neon:    return Color(red: 0.14, green: 0.13, blue: 0.25)
        case .minimal: return Color(red: 0.16, green: 0.16, blue: 0.2)
        }
    }

    var pillColor: Color {
        switch self {
        case .classic: return Color(red: 0.72, green: 0.78, blue: 0.9)
        case .neon:    return Color(red: 0.12, green: 0.11, blue: 0.22)
        case .minimal: return Color(red: 0.14, green: 0.14, blue: 0.18)
        }
    }

    var boardGlow: Color {
        switch self {
        case .classic: return Color(red: 0.54, green: 0.48, blue: 0.86).opacity(0.2)
        case .neon:    return Color(red: 0.4, green: 0.15, blue: 0.9).opacity(0.5)
        case .minimal: return .clear
        }
    }

    /// Whether this theme uses a dark appearance.
    var isDark: Bool {
        self != .classic
    }
}
