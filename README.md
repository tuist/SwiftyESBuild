# SwiftyESBuild ⭐️

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpepicrft%2FSwiftyESBuild%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pepicrft/SwiftyESBuild)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpepicrft%2FSwiftyESBuild%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pepicrft/SwiftyESBuild)
[![Netlify Status](https://api.netlify.com/api/v1/badges/69daef71-b1cf-4d37-96ad-216cb953e668/deploy-status)](https://app.netlify.com/sites/SwiftyESBuild/deploys)
[![SwiftyESBuild](https://github.com/pepicrft/SwiftyESBuild/actions/workflows/SwiftyESBuild.yml/badge.svg)](https://github.com/pepicrft/SwiftyESBuild/actions/workflows/SwiftyESBuild.yml)


`SwiftyESBuild` is a Swift Package that wraps [ESBuild](https://esbuild.github.io) to ease bringing bundling capabilities to Swift on Server apps.

## Usage

First, you need to add `SwiftyESBuild` as a dependency in your project's `Package.swift`:

```swift
.package(url: "https://github.com/pepicrft/SwiftyESBuild.git", .upToNextMinor(from: "0.1.0"))
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

## Sponsor ❤️

If you appreciate this work, I kindly invite you to consider [sponsoring me](https://github.com/sponsors/pepicrft). Your support brings me one step closer to realizing my dream of making a living through open source contributions. With your sponsorship, I can continue dedicating my time and effort to creating valuable open source projects and providing ongoing support to the community. Together, let's fuel the advancement of open source and pave the way for a sustainable future.