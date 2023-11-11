# Changelog

## Unreleased

## 0.3.0

### What's changed
- We fixed a compatibility issue with the `aarch64` architecture.

**Full Changelog**: https://github.com/tuist/SwiftyESBuild/compare/0.2.0...0.3.0

## 0.2.0

### Added

- Added missing basic options to `SwiftyESBuild.RunOption`.
- Added documentation to every case in `SwiftyESBuild.RunOption`.
- Added a "Get started" page to the documentation catalog.

### Changed

- Don't start `esbuild` in a new process to ensure it gets killed when the Swift process (parent process) exits [commit](h) by [@pepicrft](https://github.com/pepicrft)