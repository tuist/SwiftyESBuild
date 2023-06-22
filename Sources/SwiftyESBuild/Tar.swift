import Foundation
import TSCBasic
import Logging

/**
 A protocol that defines the interface to extract the content from a tar file.
 */
protocol Tarring {
    /**
     It extracts the content from the given tar file. If throws if the underlying `tar` command errors.
     */
    func extract(tar: AbsolutePath) async throws
}

/**
 Default implementation of the `Tarring` protocol.
 */
class Tar: Tarring {
    let logger: Logger
    
    /**
     Default constructor.
     */
    init() {
        self.logger = Logger(label: "me.pepicrft.SwiftyESBuild.Tar")
    }
    
    func extract(tar: AbsolutePath) async throws {
        let process = Process(arguments: ["/usr/bin/env","tar", "-xvf", tar.pathString], workingDirectory: tar.parentDirectory)
        _ = try process.launch()
        try await process.waitUntilExit()
    }
}
