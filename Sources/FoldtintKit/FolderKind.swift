enum FolderKind: Equatable, Sendable {
    case missing
    case file
    case symbolicLink
    case package
    case directory
}
