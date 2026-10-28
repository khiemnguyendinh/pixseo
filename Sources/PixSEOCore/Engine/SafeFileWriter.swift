import Darwin
import Foundation

/// Writes a new file without ever replacing an existing one.
///
/// Data goes to a hidden temporary file in the destination folder, which is then renamed with
/// `RENAME_EXCL`: the kernel refuses atomically if the name was taken in the meantime, so even a
/// race with another program can't overwrite anything. The original image is never opened for writing.
public enum SafeFileWriter {
    public static func write(_ data: Data, to destination: URL) throws {
        let directory = destination.deletingLastPathComponent()
        let temporary = directory.appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).pixseo-tmp")

        do {
            try data.write(to: temporary, options: .withoutOverwriting)
        } catch let error as CocoaError {
            throw map(error, directory: directory)
        }

        let renamed = temporary.path.withCString { from in
            destination.path.withCString { to in renamex_np(from, to, UInt32(RENAME_EXCL)) }
        }
        guard renamed == 0 else {
            let code = errno
            try? FileManager.default.removeItem(at: temporary)
            switch code {
            case EEXIST: throw ExportError.destinationExists(destination)
            case EACCES, EPERM, EROFS: throw ExportError.permissionDenied(directory: directory)
            case ENOSPC: throw ExportError.diskFull
            default: throw ExportError.encodeFailed
            }
        }
    }

    private static func map(_ error: CocoaError, directory: URL) -> ExportError {
        switch error.code {
        case .fileWriteNoPermission, .fileWriteVolumeReadOnly: .permissionDenied(directory: directory)
        case .fileWriteOutOfSpace: .diskFull
        default: .encodeFailed
        }
    }
}
