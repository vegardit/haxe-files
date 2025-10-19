# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Fixed
- Path.getAbsolutePath() returns path with forward-slahses on Windows

## [4.0.4] - 2025-06-07

### Changed
- support JVM target


## [4.0.3] - 2023-05-07

### Changed
- solve deprecation warnings


## [4.0.2] - 2023-02-16

### Fixed
- `Path.of("non-existing-file").exists()` always returns `true` on Hashlink because of https://github.com/HaxeFoundation/haxe/issues/10970


## [4.0.1] - 2023-01-14

### Fixed
- Lua support
- [#13](https://github.com/vegardit/haxe-files/pull/13) File.writeString fails with Flash/AIR (thanks to [Tahir](https://github.com/TheWorldMachinima))


## [4.0.0] - 2022-05-06

### Fixed
- [#10](https://github.com/vegardit/haxe-files/pull/10) Windows/MacOS platform detection (thanks to [redchew](https://github.com/redchew))

### Changed
- minimum required Haxe version is now 4.2


## [3.0.0] - 2021-08-07

### Fixed
- NPE in FileWatcher in case of very fast file operations (create/delete)
- PollingFileWatcher does not create deletion event for entries of deleted directories

### Changed
- enabled null safety
- `Path.of(null)` now throws an exception


## [2.0.0] - 2020-04-22

### Added
- support eval target

### Changed
- minimum required Haxe version is now 4.x
- removed support for old PHP5 target


## [1.2.1] - 2019-06-02

### Fixed
- [Issue#3](https://github.com/vegardit/haxe-files/issues/3) `Enum<cs.system.Environment_SpecialFolder> has no field UserProfile` on .NET 3.5 or lower


## [1.2.0] - 2019-05-19

### Added
- Dir.getUserHome()
- automatically set compiler define 'filesystem_support' if the target can access the local filesystem

### Fixed
- Dir.copyTo() with MERGE not working with PhantomJS
- Dir.getCWD() not working with PhantomJS


## [1.1.1] - 2018-08-22

### Fixed
- [PR#1](https://github.com/vegardit/haxe-files/pull/1) File#openInput() and File#openOutput() not visible
- removed left-over trace statement


## [1.1.0] - 2018-04-24

### Added
- hx.files.Path#isRoot
- hx.files.Dir#copyTo
- hx.files.watcher.JavaFileWatcher

### Changed
- using Enum options for hx.files.Dir#moveTo/#renameTo, hx.files.File#copyTo/#moveTo/#renameTo

### Fixed
- [lua] Dir.createDirectory() does not work recursively because of https://github.com/HaxeFoundation/haxe/issues/6946


## [1.0.0] - 2018-04-19

### Added
- Initial release
