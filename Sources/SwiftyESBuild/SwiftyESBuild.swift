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
         Flag: --bundle
         */
        case bundle

        /**
         The output file (for one entry point)
         Flag --outfile
         */
        case outfile(AbsolutePath)
        
        /**
         Passes the arguments as raw values to the executable.
         {...arguments}
         */
        case arguments([String])
        
        /**
         Substitute substituted with substitute while parsing
         Flag: --define
         */
        case define(substituted: String, substitute: String)
        
        /**
         Excludes the Javascript module that matches the given wildcard from the bundle:
         Flag: --external
         */
        case external(wildcard: String)
        
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
            case .define(let substituted, let substitute):
                return ["--define:\(substituted)=\(substitute)"]
            case .external(let wildcard):
                return ["--external:\(wildcard)"]
            }
        }
    }
}

/**
 Simple options:
   --bundle              Bundle all dependencies into the output files
   --define:K=V          Substitute K with V while parsing
   --external:M          Exclude module M from the bundle (can use * wildcards)
   --format=...          Output format (iife | cjs | esm, no default when not
                         bundling, otherwise default is iife when platform
                         is browser and cjs when platform is node)
   --loader:X=L          Use loader L to load file extension X, where L is
                         one of: base64 | binary | copy | css | dataurl |
                         empty | file | js | json | jsx | text | ts | tsx
   --minify              Minify the output (sets all --minify-* flags)
   --outdir=...          The output directory (for multiple entry points)
   --outfile=...         The output file (for one entry point)
   --packages=...        Set to "external" to avoid bundling any package
   --platform=...        Platform target (browser | node | neutral,
                         default browser)
   --serve=...           Start a local HTTP server on this host:port for outputs
   --sourcemap           Emit a source map
   --splitting           Enable code splitting (currently only for esm)
   --target=...          Environment target (e.g. es2017, chrome58, firefox57,
                         safari11, edge16, node10, ie9, opera45, default esnext)
   --watch               Watch mode: rebuild on file system changes (stops when
                         stdin is closed, use "--watch=forever" to ignore stdin)

 Advanced options:
   --allow-overwrite         Allow output files to overwrite input files
   --analyze                 Print a report about the contents of the bundle
                             (use "--analyze=verbose" for a detailed report)
   --asset-names=...         Path template to use for "file" loader files
                             (default "[name]-[hash]")
   --banner:T=...            Text to be prepended to each output file of type T
                             where T is one of: css | js
   --certfile=...            Certificate for serving HTTPS (see also "--keyfile")
   --charset=utf8            Do not escape UTF-8 code points
   --chunk-names=...         Path template to use for code splitting chunks
                             (default "[name]-[hash]")
   --color=...               Force use of color terminal escapes (true | false)
   --drop:...                Remove certain constructs (console | debugger)
   --entry-names=...         Path template to use for entry point output paths
                             (default "[dir]/[name]", can also use "[hash]")
   --footer:T=...            Text to be appended to each output file of type T
                             where T is one of: css | js
   --global-name=...         The name of the global for the IIFE format
   --ignore-annotations      Enable this to work with packages that have
                             incorrect tree-shaking annotations
   --inject:F                Import the file F into all input files and
                             automatically replace matching globals with imports
   --jsx-dev                 Use React's automatic runtime in development mode
   --jsx-factory=...         What to use for JSX instead of React.createElement
   --jsx-fragment=...        What to use for JSX instead of React.Fragment
   --jsx-import-source=...   Override the package name for the automatic runtime
                             (default "react")
   --jsx-side-effects        Do not remove unused JSX expressions
   --jsx=...                 Set to "automatic" to use React's automatic runtime
                             or to "preserve" to disable transforming JSX to JS
   --keep-names              Preserve "name" on functions and classes
   --keyfile=...             Key for serving HTTPS (see also "--certfile")
   --legal-comments=...      Where to place legal comments (none | inline |
                             eof | linked | external, default eof when bundling
                             and inline otherwise)
   --log-level=...           Disable logging (verbose | debug | info | warning |
                             error | silent, default info)
   --log-limit=...           Maximum message count or 0 to disable (default 6)
   --log-override:X=Y        Use log level Y for log messages with identifier X
   --main-fields=...         Override the main file order in package.json
                             (default "browser,module,main" when platform is
                             browser and "main,module" when platform is node)
   --mangle-cache=...        Save "mangle props" decisions to a JSON file
   --mangle-props=...        Rename all properties matching a regular expression
   --mangle-quoted=...       Enable renaming of quoted properties (true | false)
   --metafile=...            Write metadata about the build to a JSON file
                             (see also: https://esbuild.github.io/analyze/)
   --minify-whitespace       Remove whitespace in output files
   --minify-identifiers      Shorten identifiers in output files
   --minify-syntax           Use equivalent but shorter syntax in output files
   --out-extension:.js=.mjs  Use a custom output extension instead of ".js"
   --outbase=...             The base path used to determine entry point output
                             paths (for multiple entry points)
   --preserve-symlinks       Disable symlink resolution for module lookup
   --public-path=...         Set the base URL for the "file" loader
   --pure:N                  Mark the name N as a pure function for tree shaking
   --reserve-props=...       Do not mangle these properties
   --resolve-extensions=...  A comma-separated list of implicit extensions
                             (default ".tsx,.ts,.jsx,.js,.css,.json")
   --servedir=...            What to serve in addition to generated output files
   --source-root=...         Sets the "sourceRoot" field in generated source maps
   --sourcefile=...          Set the source file for the source map (for stdin)
   --sourcemap=external      Do not link to the source map with a comment
   --sourcemap=inline        Emit the source map with an inline data URL
   --sources-content=false   Omit "sourcesContent" in generated source maps
   --supported:F=...         Consider syntax F to be supported (true | false)
   --tree-shaking=...        Force tree shaking on or off (false | true)
   --tsconfig=...            Use this tsconfig.json file instead of other ones
   --version                 Print the current version (0.18.6) and exit

 Examples:
   # Produces dist/entry_point.js and dist/entry_point.js.map
   esbuild --bundle entry_point.js --outdir=dist --minify --sourcemap

   # Allow JSX syntax in .js files
   esbuild --bundle entry_point.js --outfile=out.js --loader:.js=jsx

   # Substitute the identifier RELEASE for the literal true
   esbuild example.js --outfile=out.js --define:RELEASE=true

   # Provide input via stdin, get output via stdout
   esbuild --minify --loader=ts < input.ts > output.js

   # Automatically rebuild when input files are changed
   esbuild app.ts --bundle --watch

   # Start a local HTTP server for everything in "www"
   esbuild app.ts --bundle --servedir=www --outdir=www/js
 */
