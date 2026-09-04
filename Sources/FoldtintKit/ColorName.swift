import ArgumentParser

/// Finder tag colors. Hex codes are not valid for folder tint.
enum ColorName: String, CaseIterable, Codable, Sendable, ExpressibleByArgument {
    case gray
    case green
    case purple
    case blue
    case yellow
    case red
    case orange

    static let defaultColor = ColorName.purple

    /// Finder stores the tag color as an index from 1 to 7.
    var tagColorIndex: Int {
        switch self {
        case .gray:
            return 1
        case .green:
            return 2
        case .purple:
            return 3
        case .blue:
            return 4
        case .yellow:
            return 5
        case .red:
            return 6
        case .orange:
            return 7
        }
    }

    init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}
