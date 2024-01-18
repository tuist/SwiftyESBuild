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
       - version: The version of ESBuild to use. You can specify a fixed version or use the latest one.
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
                    options: RunOption...) async throws
    {
        try await run(entryPoint: entryPoint, directory: entryPoint.parentDirectory, options: options)
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
                    options: RunOption...) async throws
    {
        try await run(entryPoint: entryPoint, directory: directory, options: options)
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
                    options: [RunOption]) async throws
    {
        let executablePath = try await download()
        var arguments = [entryPoint.pathString]
        arguments.append(contentsOf: options.flatMap(\.flag))
        try await executor.run(executablePath: executablePath, directory: directory, arguments: arguments)
    }

    /**
     Downloads the ESBuild portable executable.
     */
    private func download() async throws -> AbsolutePath {
        try await downloader.download(version: version, directory: directory)
    }
}

extension Set<SwiftyESBuild.RunOption> {
    /**
     Returns the flags to pass to the ESBuild CLI when invoking the `init` command.
     */
    var executableFlags: [String] {
        map(\.flag).flatMap { $0 }
    }
}

public extension SwiftyESBuild {
    /**
     An enum that represents the various JavaScript module systems supported by ESBuild.
     */
    enum Format: String {
        case iife
        case esm
        case cjs
    }

    /**
     An enum that represents the loaders supported by ESBuild.
     */
    enum Loader: String {
        case base64
        case binary
        case copy
        case css
        case dataurl
        case empty
        case file
        case js
        case json
        case jsx
        case text
        case ts
        case tsx
    }

    /**
     An enum that represents the JavaScript environments that ESBuild can target.
     */
    enum Target: String {
        case es2017
        case chrome58
        case safari11
        case edge16
        case node10
        case ie9
        case opera45
        case esnext
    }

    /**
     An enum that represents the platforms that ESBuild can output Javascript for.
     */
    enum Platform: String {
        case browser
        case node
        case neutral
    }

    /**
     An enum that represents the various options that can be passed as `--packages` flag to the ESBuild CLI.
     */
    enum Packages: String {
        case external
    }

    /**
     An enum that represents the various options that can be passed as `--sourcemap` flag to the ESBuild CLI.
     You can read more about the options in the [official documentation.](https://esbuild.github.io/api/#sourcemap)
     */
    enum Sourcemap: String {
        case linked
        case external
        case inline
        case both
    }

    /**
     An enum that captures all the options that that you can pass to the ESBuild executable.
     */
    enum RunOption: Hashable {
        /**
         Passes the arguments as raw values to the executable.
         {...arguments}
         */
        case arguments([String])

        /**
         To bundle a file means to inline any imported dependencies into the file itself. This process is recursive so dependencies of dependencies (and so on) will also be inlined. By default esbuild will not bundle the input files.
         - [Documentation](https://esbuild.github.io/api/#bundle)
         - **Flag:** `--bundle`
         */
        case bundle

        /**
         This option sets the output file name for the build operation. This is only applicable if there is a single entry point. If there are multiple entry points, you must use the outdir option instead to specify an output directory.
         - [Documentation](https://esbuild.github.io/api/#outfile)
         - **Flag:** `--outfile`
         */
        case outfile(AbsolutePath)

        /**
         This feature provides a way to replace global identifiers with constant expressions. It can be a way to change the behavior some code between builds without changing the code itself.

         - [Documentation](https://esbuild.github.io/api/#define)
         - **Flag:** `--define`

         ## CLI Example
         ```bash
         echo 'hooks = DEBUG && require("hooks")' | esbuild --define:DEBUG=true
         hooks = require("hooks");
         ```
         */
        case define(substituted: String, substitute: String)

        /**
         You can mark a file or a package as external to exclude it from your build. Instead of being bundled, the import will be preserved (using `require` for the `iife` and `cjs` formats and using `import` for the `esm` format) and will be evaluated at run time instead.

         This has several uses. First of all, it can be used to trim unnecessary code from your bundle for a code path that you know will never be executed. For example, a package may contain code that only runs in node but you will only be using that package in the browser. It can also be used to import code in node at run time from a package that cannot be bundled. For example, the `fsevents` package contains a native extension, which esbuild doesn't support.

         - [Documentation](https://esbuild.github.io/api/#external)
         - **Flag:** `--external`

         ## CLI Example

         ```bash
         echo 'require("fsevents")' > app.js
         esbuild app.js --bundle --external:fsevents --platform=node
         // app.js
         require("fsevents");
         ```
         */
        case external(wildcard: String)

        /**
         This sets the output format for the generated JavaScript files. There are currently three possible values that can be configured: `iife`, `cjs`, and `esm`. When no output format is specified, esbuild picks an output format for you if bundling is enabled (as described below), or doesn't do any format conversion if [bundling](https://esbuild.github.io/api/#bundle) is disabled.

         - [Documentation](https://esbuild.github.io/api/#format)
         - **Flag:** `--format`
         */
        case format(Format)

        /**
         This option changes how a given input file is interpreted. For example, the [js](https://esbuild.github.io/content-types/#javascript) loader interprets the file as JavaScript and the css loader interprets the file as CSS. See the [content types](https://esbuild.github.io/content-types/) page for a complete list of all built-in loaders.

         Configuring a loader for a given file type lets you load that file type with an import statement or a require call.

         - [Documentation](https://esbuild.github.io/api/#loader)
         - **Flags:** `--loader`

         ## CLI Example
         ```js
         import url from './example.png'
         let image = new Image
         image.src = url
         document.body.appendChild(image)

         import svg from './example.svg'
         let doc = new DOMParser().parseFromString(svg, 'application/xml')
         let node = document.importNode(doc.documentElement, true)
         document.body.appendChild(node)
         ```
         */
        case loader(extension: String, loader: Loader)

        /**
         When enabled, the generated code will be minified instead of pretty-printed. Minified code is generally equivalent to non-minified code but is smaller, which means it downloads faster but is harder to debug. Usually you minify code in production but not in development.

         - [Documentation](https://esbuild.github.io/api/#minify)
         - **Flag:** `--minify`

         ### CLI Example
         ```bash
         echo 'fn = obj => { return obj.x }' | esbuild --minify
         fn=n=>n.x;
         ```
         */
        case minify

        /**
         This option sets the output directory for the build operation.

         The output directory will be generated if it does not already exist, but it will not be cleared if it already contains some files. Any generated files will silently overwrite existing files with the same name. You should clear the output directory yourself before running esbuild if you want the output directory to only contain files from the current run of esbuild.

         If your build contains multiple entry points in separate directories, the directory structure will be replicated into the output directory starting from the [lowest common ancestor](https://en.wikipedia.org/wiki/Lowest_common_ancestor) directory among all input entry point paths. For example, if there are two entry points `src/home/index.ts` and `src/about/index.ts`, the output directory will contain `home/index.js` and `about/index.js`. If you want to customize this behavior, you should change the [outbase directory](https://esbuild.github.io/api/#outbase).

         ## CLI Example

         - [Documentation](https://esbuild.github.io/api/#outdir)
         - **Flag:** `--outdir`

         ```bash
         esbuild app.js --bundle --outdir=out
         ```
         */
        case outdir(AbsolutePath)

        /**
         Enabling watch mode tells esbuild to listen for changes on the file system and to automatically rebuild whenever a file changes that could invalidate the build.

         - [Documentation](https://esbuild.github.io/api/#watch)
         - **Flag:** `--watch`

         ## CLI Example

         ```bash
         esbuild app.js --outfile=out.js --bundle --watch
         # [watch] build finished, watching for changes...
         ```
         */
        case watch(forever: Bool = false)
        /**
         Source maps can make it easier to debug your code. They encode the information necessary to translate from a line/column offset in a generated output file back to a line/column offset in the corresponding original input file. This is useful if your generated code is sufficiently different from your original code (e.g. your original code is TypeScript or you enabled [minification](https://esbuild.github.io/api/#minify)). This is also useful if you prefer looking at individual files in your browser's developer tools instead of one big bundled file.

         Note that source map output is supported for both JavaScript and CSS, and the same options apply to both. Everything below that talks about `.js` files also applies similarly to `.css` files.

         - [Documentation](https://esbuild.github.io/api/#sourcemap)
         - **Flag:** `--sourcemap`

         ## CLI Example

         ```bash
         esbuild app.ts --sourcemap --outfile=out.js
         ```
         */
        case sourcemap(Sourcemap? = nil)
        /**
         This enables "code splitting" which serves two purposes:

         - Code shared between multiple entry points is split off into a separate shared file that both entry points import. That way if the user first browses to one page and then to another page, they don't have to download all of the JavaScript for the second page from scratch if the shared part has already been downloaded and cached by their browser.

         - Code referenced through an asynchronous import() expression will be split off into a separate file and only loaded when that expression is evaluated. This allows you to improve the initial download time of your app by only downloading the code you need at startup, and then lazily downloading additional code if needed later.

         Without code splitting enabled, an `import()` expression becomes `Promise.resolve().then(() => require())` instead. This still preserves the asynchronous semantics of the expression but it means the imported code is included in the same bundle instead of being split off into a separate file.

         When you enable code splitting you must also configure the output directory using the outdir setting:

         - [Documentation](https://esbuild.github.io/api/#splitting)
         - **Flag:** `--splitting`

         ## CLI Example
         ```bash
         esbuild home.ts about.ts --bundle --splitting --outdir=out --format=esm
         ```
         */
        case splitting
        /**
         This sets the target environment for the generated JavaScript and/or CSS code. It tells esbuild to transform JavaScript syntax that is too new for these environments into older JavaScript syntax that will work in these environments. For example, the `??` operator was introduced in Chrome 80 so esbuild will convert it into an equivalent (but more verbose) conditional expression when targeting Chrome 79 or earlier.

         - [Documentation](https://esbuild.github.io/api/#target)
         - **Flag:** `--target`

         ## CLI Example
         ```bash
         esbuild app.js --target=es2020,chrome58,edge16,firefox57,node12,safari11
         ```
         */
        case target([Target])
        /**
         By default, esbuild's bundler is configured to generate code intended for the browser. If your bundled code is intended to run in node instead, you should set the platform to node.

         - [Documentation](https://esbuild.github.io/api/#platform)
         - **Flag:** `--platform`

         ## CLI Example
         ```bash
         esbuild app.js --bundle --platform=node
         ```
         */
        case platform(Platform)

        /**
         Serve mode starts a web server that serves your code to your browser on your device.

         - [Documentation](https://esbuild.github.io/api/#serve)
         - **Flag:** `--serve`

         ## CLI Example

         ```bash
         # Enable serve mode
         --serve

         # Set the port
         --serve=9000

         # Set the host and port (IPv4)
         --serve=127.0.0.1:9000

         # Set the host and port (IPv6)
         --serve=[::1]:9000

         # Set the directory to serve
         --servedir=www

         # Enable HTTPS
         --keyfile=your.key --certfile=your.cert
         ```
         */
        case serve(String? = nil)
        /**
         Use this setting to exclude all of your package's dependencies from the bundle. This is useful when bundling for node because many npm packages use node-specific features that esbuild doesn't support while bundling (such as `__dirname`, `import.meta.url`, `fs.readFileSync`, and *.node native binary modules).

         - [Documentation](https://esbuild.github.io/api/#packages)
         - **Flag:** `--packages`

         ## CLI Example
         ```bash
         esbuild app.js --bundle --packages=external
         ```

         */
        case packages(Packages)

        /**
         The CLI flag that represents the option.
         */
        var flag: [String] {
            switch self {
            case .bundle: return ["--bundle"]
            case let .outfile(outputFilePath):
                return ["--outfile=\(outputFilePath.pathString)"]
            case let .arguments(arguments):
                return arguments
            case let .define(substituted, substitute):
                return ["--define:\(substituted)=\(substitute)"]
            case let .external(wildcard):
                return ["--external:\(wildcard)"]
            case let .format(format):
                return ["--format=\(format.rawValue)"]
            case let .loader(ext, loader):
                return ["--loader:\(ext):\(loader.rawValue)"]
            case .minify:
                return ["--minify"]
            case let .outdir(outDir):
                return ["--outdir=\(outDir.pathString)"]
            case let .watch(forever):
                if forever {
                    return ["--watch=forever"]
                } else {
                    return ["--watch"]
                }
            case let .sourcemap(sourcemap):
                if let sourcemap {
                    return ["--sourcemap=\(sourcemap.rawValue)"]
                } else {
                    return ["--sourcemap"]
                }
            case .splitting:
                return ["--splitting"]
            case let .target(targets):
                return ["--target=\(targets.map(\.rawValue).joined(separator: ","))"]
            case let .platform(platform):
                return ["--platform=\(platform.rawValue)"]
            case let .serve(serve):
                if let serve {
                    return ["--serve=\(serve)"]
                } else {
                    return ["--serve"]
                }
            case let .packages(packages):
                return ["--packages=\(packages.rawValue)"]
            }
        }
    }
}
