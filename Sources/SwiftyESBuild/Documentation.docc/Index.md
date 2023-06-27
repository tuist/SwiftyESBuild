# Get started

`SwiftyESBuild` is a Swift Package that wraps [ESBuild](https://esbuild.github.io) to ease bringing bundling capabilities to Swift on Server apps.


## Usage

First, you need to add `SwiftyESBuild` as a dependency in your project's `Package.swift`:

```swift
.package(url: "https://github.com/tuist/SwiftyESBuild.git", .upToNextMinor(from: "0.2.0"))
```

Once added, you'll create an instance of `SwiftyESBuild` specifying the version you'd like to use and where you'd like it to be downloaded.

```swift
let esbuild = SwiftyESBuild(version: .latest, directory: "./cache")
```

If you don't pass any argument, it defaults to the latest version in the system's default temporary directory. If you work in a team, we recommend fixing the version to minimize non-determinism across environments.

### Running ESBuild

To run ESBuild you need to invoke the `run` function:

```swift
import TSCBasic // AbsolutePath

let entryPointPath = AbsolutePath(validating: "/project/index.js")
let outputBundlePath = AbsolutePath(validating: "/projects/build/index.js")
try await esbuild.run(entryPoint: entryPointPath, options: .bundle, .outfile(outputBundlePath))
```
