import AsyncHTTPClient
import Foundation
import Logging
import NIOCore
import NIOFoundationCompat
import TSCBasic
import TSCUtility

/**
 It represents the payload returned by the https://registry.npmjs.org/{package} URL. SwiftyESBuild uses the information in the payload to determine the latest version and the URL from where we can download a given version.
 */
struct NPMPackage: Decodable {
    struct DistTags: Decodable {
        let latest: String
    }

    struct Version: Decodable {
        struct Dist: Decodable {
            let tarball: String
            let shasum: String
            let integrity: String
        }

        let dist: Dist
    }

    let name: String
    let distTags: DistTags
    let versions: [String: Version]

    enum CodingKeys: String, CodingKey {
        case distTags = "dist-tags"
        case versions
        case name
    }
}

/*
 An enum that represents the various errors that the `Downloader` can throw.
 */
enum DownloaderError: LocalizedError {
    /**
     This error is thrown when we can't determine the NPM packag ename.
     */
    case unableToDeterminePackageName

    /**
     This error is thrown when the version can't be found in the payload returned by the NPM registry.
     */
    case versionNotFound(String)

    var errorDescription: String? {
        switch self {
        case .unableToDeterminePackageName:
            return "We were unable to determine ESBuild's package name for this architecture and OS."
        case let .versionNotFound(version):
            return "The payload returned by https://registry.npmjs.org/@esbuild/{os}-{arch} doesn't contain the version \(version)"
        }
    }
}

protocol Downloading {
    /**
     It downloads the latest version of ESBuild in a default directory.
     */
    func download() async throws -> AbsolutePath
    /**
     It downloads the given version of ESBuild in the given directory.
     */
    func download(version: ESBuildVersion, directory: AbsolutePath) async throws -> AbsolutePath
}

class Downloader: Downloading {
    let architectureDetector: ArchitectureDetecting
    let logger: Logger
    let tar: Tarring

    /**
     Returns the default directory where ESBuild binaries should be downloaded.
     */
    static func defaultDownloadDirectory() -> AbsolutePath {
        try! localFileSystem.tempDirectory.appending(component: "SwiftyESBuild")
    }

    init(architectureDetector: ArchitectureDetecting = ArchitectureDetector(),
         tar: Tarring = Tar())
    {
        self.architectureDetector = architectureDetector
        logger = Logger(label: "io.tuist.SwiftyESBuild.Downloader")
        self.tar = tar
    }

    func download() async throws -> TSCBasic.AbsolutePath {
        try await download(version: .latest, directory: Downloader.defaultDownloadDirectory())
    }

    func download(version: ESBuildVersion,
                  directory: AbsolutePath) async throws -> AbsolutePath
    {
        let npmPackage = try await npmPackage()
        let expectedVersion = try await versionToDownload(version: version, npmPackage: npmPackage)
        let binaryPath = directory.appending(components: [expectedVersion, "esbuild"])
        if localFileSystem.exists(binaryPath) { return binaryPath }
        try await downloadBinary(npmPackage: npmPackage, version: expectedVersion, to: binaryPath)
        return binaryPath
    }

    // MARK: - Private

    private func downloadBinary(npmPackage: NPMPackage, version: String, to downloadPath: AbsolutePath) async throws {
        if !localFileSystem.exists(downloadPath.parentDirectory) {
            logger.debug("Creating directory \(downloadPath.parentDirectory)")
            try localFileSystem.createDirectory(downloadPath.parentDirectory, recursive: true)
        }
        guard let npmVersion = npmPackage.versions[version]?.dist else {
            throw DownloaderError.versionNotFound(version)
        }

        logger.debug("Downloading \(npmPackage.name) from \(npmVersion.tarball)...")
        let client = HTTPClient(eventLoopGroupProvider: .singleton)

        do {
            try await withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
                let tgzPath = tmpDir.appending(component: "esbuild.tgz")

                let request = try HTTPClient.Request(url: URL(string: npmVersion.tarball)!)
                let delegate = try FileDownloadDelegate(path: tgzPath.pathString, reportProgress: { [weak self] in
                    if let totalBytes = $0.totalBytes {
                        self?.logger.debug("Total bytes count: \(totalBytes)")
                    }
                    self?.logger.debug("Downloaded \($0.receivedBytes) bytes so far")
                })

                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    client.execute(request: request, delegate: delegate).futureResult.whenComplete { result in
                        switch result {
                        case .success:
                            Task {
                                do {
                                    // TODO: Do checksum validation
                                    try await self.tar.extract(tar: tgzPath)
                                    let binaryPath = tgzPath.parentDirectory.appending(.init("package/bin/esbuild"))
                                    try localFileSystem.chmod(.executable, path: binaryPath)
                                    try localFileSystem.move(from: binaryPath, to: downloadPath)
                                    continuation.resume()
                                } catch {
                                    print(error)
                                    continuation.resume(throwing: error)
                                    return
                                }
                            }
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        } catch {
            try await client.shutdown()
            throw error
        }
        try await client.shutdown()
    }

    /**
     Returns the version that should be downloaded.
     */
    private func versionToDownload(version: ESBuildVersion, npmPackage: NPMPackage) async throws -> String {
        switch version {
        case let .fixed(rawVersion):
            if rawVersion.starts(with: "v") {
                return rawVersion
            } else {
                /**
                 Releases on GitHub are prefixed with "v" so we need to include it.
                 */
                return "v\(rawVersion)"
            }
        case .latest: return npmPackage.distTags.latest
        }
    }

    /**
     It returns the NPM package metadata from the https://registry.npmjs.org/{package-name} URL.
     ESBuild has a package per architecture and OS supported. For example, we can obtain the metadata
     for the package for macOS arm64 from:
     https://registry.npmjs.org/@esbuild/darwin-arm64
     */
    private func npmPackage() async throws -> NPMPackage {
        guard let npmPackageName = npmPackageName() else {
            throw DownloaderError.unableToDeterminePackageName
        }
        let packageURL = "https://registry.npmjs.org/\(npmPackageName)"
        logger.debug("Getting the package metadata from \(packageURL)")

        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)

        var package: NPMPackage!
        do {
            var request = HTTPClientRequest(url: packageURL)
            request.headers.add(name: "Content-Type", value: "application/json")
            request.headers.add(name: "User-Agent", value: "io.tuist.SwiftyESBuild")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            let body = try await response.body.collect(upTo: 1024 * 1024)
            package = try JSONDecoder().decode(NPMPackage.self, from: Data(buffer: body))
        } catch {
            try await httpClient.shutdown()
            throw error
        }

        try await httpClient.shutdown()

        return package
    }

    /**
        It returns the name of the NPM package for the current OS and architecture. The name follows the convention:
        @esbuild/{os}-{arch}
        For example @esbuild/darwin-arm64
     */
    private func npmPackageName() -> String? {
        guard let architecture = architectureDetector.architecture()?.esbuildValue else {
            return nil
        }
        var os: String!
        #if os(Windows)
            os = "windows"
        #elseif os(Linux)
            os = "linux"
        #else
            os = "darwin"
        #endif
        return "@esbuild/\(os!)-\(architecture)"
    }
}
