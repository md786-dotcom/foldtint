import Darwin
import Foundation

enum ExtendedAttribute {
    static let tagsName = "com.apple.metadata:_kMDItemUserTags"

    /// Do not follow a symbolic link. A link can leave the Desktop folder.
    private static let noFollow = XATTR_NOFOLLOW

    static func read(name: String, from url: URL) throws -> Data? {
        try url.withUnsafeFileSystemRepresentation { pointer in
            guard let pointer else {
                throw FoldtintError.tagRead
            }
            let size = getxattr(pointer, name, nil, 0, 0, noFollow)
            if size < 0 {
                return try nilIfMissing()
            }
            var buffer = Data(count: Int(size))
            let written = buffer.withUnsafeMutableBytes { raw in
                getxattr(pointer, name, raw.baseAddress, Int(size), 0, noFollow)
            }
            if written < 0 {
                throw FoldtintError.tagRead
            }
            return buffer
        }
    }

    static func write(name: String, data: Data, to url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { pointer in
            guard let pointer else {
                throw FoldtintError.tagWrite
            }
            let result = data.withUnsafeBytes { raw in
                setxattr(pointer, name, raw.baseAddress, data.count, 0, noFollow)
            }
            if result != 0 {
                throw FoldtintError.tagWrite
            }
        }
    }

    static func remove(name: String, from url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { pointer in
            guard let pointer else {
                throw FoldtintError.tagWrite
            }
            let result = removexattr(pointer, name, noFollow)
            if result != 0 && errno != ENOATTR {
                throw FoldtintError.tagWrite
            }
        }
    }

    private static func nilIfMissing() throws -> Data? {
        if errno == ENOATTR {
            return nil
        }
        throw FoldtintError.tagRead
    }
}
