import Foundation

enum DesktopRoot {
    static func resolve(home: URL = FileManager.default.homeDirectoryForCurrentUser) throws -> URL {
        let desktop = home
            .appendingPathComponent("Desktop", isDirectory: true)
            .resolvingSymlinksInPath()
            .standardizedFileURL
        if PathPolicy.isBlocked(desktop.path) {
            throw FoldtintError.refusedRoot
        }
        return desktop
    }
}

enum ExecutablePath {
    static func resolve(arguments: [String] = CommandLine.arguments) -> String {
        guard let first = arguments.first else {
            return "/usr/local/bin/foldtint"
        }
        if first.hasPrefix("/") {
            return URL(fileURLWithPath: first).resolvingSymlinksInPath().path
        }
        let current = FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: current)
            .appendingPathComponent(first)
            .resolvingSymlinksInPath()
            .path
    }
}
