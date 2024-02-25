@testable import SwiftyESBuild
import TSCBasic
import TSCUtility
import XCTest

final class DownloaderTests: XCTestCase {
    func testDownloadFixedVersion() async throws {
        try await withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
            // Given
            let subject = Downloader()
            let version = "0.19.11"

            // When
            let path = try await subject.download(version: .fixed(version), directory: tmpDir)

            // Then
            XCTAssertTrue(path.pathString.hasSuffix("/\(version)/esbuild"))
        }
    }
}
