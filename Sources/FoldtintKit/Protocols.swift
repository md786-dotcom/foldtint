import Foundation

protocol FolderFileSystem {
    func kind(of url: URL) throws -> FolderKind
    func isUserImmutable(_ url: URL) throws -> Bool
    func setUserImmutable(_ flag: Bool, at url: URL) throws
    func readTags(at url: URL) throws -> [FinderTag]
    func writeTags(_ tags: [FinderTag], at url: URL) throws
    func childNames(in directory: URL) throws -> [String]
}

protocol SettingsStore {
    func load() throws -> FoldtintConfig
    func save(_ config: FoldtintConfig) throws
    func delete() throws
}

protocol AgentControl {
    func install(executable: String) throws
    func remove() throws
    func isLoaded() -> Bool
}

protocol TaskScheduling {
    func runAfter(_ delay: TimeInterval, _ body: @escaping () -> Void)
    func cancelPending()
}
