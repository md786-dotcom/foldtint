enum FoldtintError: Error, Equatable, CustomStringConvertible {
    case refusedRoot
    case unknownColor
    case configRead
    case configWrite
    case tagRead
    case tagWrite
    case agentFailed
    case missingCommand
    case extraArguments
    case blockedWrite

    var description: String {
        switch self {
        case .refusedRoot:
            return "The Desktop path is not allowed."
        case .unknownColor:
            return "The color name is not valid."
        case .configRead:
            return "The configuration file cannot be read."
        case .configWrite:
            return "The configuration file cannot be written."
        case .tagRead:
            return "The Finder tags cannot be read."
        case .tagWrite:
            return "The Finder tags cannot be written."
        case .agentFailed:
            return "The LaunchAgent command failed."
        case .missingCommand:
            return "A command name is required."
        case .extraArguments:
            return "Too many arguments."
        case .blockedWrite:
            return "The tag write is blocked."
        }
    }
}
