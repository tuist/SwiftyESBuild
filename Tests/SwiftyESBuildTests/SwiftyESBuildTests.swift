import XCTest
import TSCBasic
import TSCUtility
@testable import SwiftyESBuild

final class SwiftyESBuildTests: XCTestCase {
    func testExample() async throws {
        try await withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
            // Given
            let subject = SwiftyESBuild(directory: tmpDir)
            let aModule = """
            import run from "./b.js"
            
            run()
            """
            let bModule = """
            export default function() {
                console.log('esbuild')
            }
            """
            let aModulePath = tmpDir.appending(component: "a.js")
            let bModulePath = tmpDir.appending(component: "b.js")
            let outputBundlePath = tmpDir.appending(component: "output.js")
            try localFileSystem.writeFileContents(aModulePath, bytes: .init(encodingAsUTF8: aModule))
            try localFileSystem.writeFileContents(bModulePath, bytes: .init(encodingAsUTF8: bModule))
            
            // When
            try await subject.run(entryPoint: aModulePath, options: .bundle, .outfile(outputBundlePath))
            
            // Then
            let content = String(bytes: try localFileSystem.readFileContents(outputBundlePath).contents, encoding: .utf8)
            XCTAssertTrue(content?.contains("console.log(\"esbuild\")") ?? false)
        }
    }
}
