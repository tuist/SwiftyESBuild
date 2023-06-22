import TSCBasic

/**
 The `SwiftyESBuild` class is the main interface to lazily download and run ESBuild from a Swift process. To use, you have to create an instance of `SwiftyESBuild` and invoke it using the asynchronous function `run`.
 */
public class SwiftyESBuild {
    private let version: ESBuildVersion
    private let directory: AbsolutePath
    private let downloader: Downloading
    private let executor: Executing
    
    /**
     Default initializer.
     - Parameters:
     - version: The version of Tailwind to use. You can specify a fixed version or use the latest one.
     - directory: The directory where the executables will be downloaded. When not provided, it defaults to the system's default temporary directory.
     */
    public convenience init(version: ESBuildVersion = .latest, directory: AbsolutePath) {
        self.init(version: version, directory: directory, downloader: Downloader(), executor: Executor())
    }
    
    /**
     Default initializer.
     - Parameters:
     - version: The version of ESBuild to use. You can specify a fixed version or use the latest one.
     */
    public convenience init(version: ESBuildVersion = .latest) {
        self.init(version: version, directory: Downloader.defaultDownloadDirectory(), downloader: Downloader(), executor: Executor())
    }
    
    private init(version: ESBuildVersion,
         directory: AbsolutePath,
         downloader: Downloading,
         executor: Executing)
    {
        self.version = version
        self.directory = directory
        self.downloader = downloader
        self.executor = executor
    }
    
    /**
     Downloads the executable if needed and runs it with the given options. By default it runs the executable from the directory containing the entry point Javascript module.
     
     - Parameters:
        - entryPoint: The path to the entry point Javascript module that ESBuild will use to traverse the module graph and generate the output bundle.
        - options: A set of options to pass to the ESBuild executable to configure the bundling.
     */
    public func run(entryPoint: AbsolutePath,
                    options: RunOption...) async throws {
        return try await run(entryPoint: entryPoint, directory: entryPoint.parentDirectory, options: options)
    }

    /**
     Downloads the executable if needed and runs it with the given options.
     
     - Parameters:
        - entryPoint: The path to the entry point Javascript module that ESBuild will use to traverse the module graph and generate the output bundle.
        - directory: Working directory from where to run the ESBuild executable.
        - options: A set of options to pass to the ESBuild executable to configure the bundling.
     */
    public func run(entryPoint: AbsolutePath,
                    directory: AbsolutePath,
                    options: RunOption...) async throws {
        return try await run(entryPoint: entryPoint, directory: directory, options: options)
    }
    
    /**
     Downloads the executable if needed and runs it with the given options.
     
     - Parameters:
        - entryPoint: The path to the entry point Javascript module that ESBuild will use to traverse the module graph and generate the output bundle.
        - directory: Working directory from where to run the ESBuild executable.
        - options: A set of options to pass to the ESBuild executable to configure the bundling.
     */
    public func run(entryPoint: AbsolutePath,
                    directory: AbsolutePath,
                    options: [RunOption]) async throws {
        let executablePath = try await download()
        var arguments = [entryPoint.pathString]
        arguments.append(contentsOf: options.flatMap(\.flag))
        try await executor.run(executablePath: executablePath, directory: directory, arguments: arguments)
    }
    
    /**
     Downloads the Tailwind portable executable
     */
    private func download() async throws -> AbsolutePath {
        try await downloader.download(version: version, directory: directory)
    }
}

extension Set where Element == SwiftyESBuild.RunOption {
    /**
     Returns the flags to pass to the Tailwind CLI when invoking the `init` command.
     */
    var executableFlags: [String] {
        return self.map(\.flag).flatMap({$0})
    }
}

public extension SwiftyESBuild {
    /**
     An enum that captures all the options that that you can pass to the ESBuild executable.
     */
    enum RunOption: Hashable {
        /**
         Bundle all dependencies into the output files
         */
        case bundle

        /**
         The output file (for one entry point)
         */
        case outfile(AbsolutePath)
        
        /**
         Passes the arguments as raw values to the executable.
         */
        case arguments([String])
        
        /**
         The CLI flag that represents the option.
         */
        var flag: [String] {
            switch self {
            case .bundle: return ["--bundle"]
            case .outfile(let outputFilePath):
                return ["--outfile=\(outputFilePath.pathString)"]
            case .arguments(let arguments):
                return arguments
            }
        }
    }
}
