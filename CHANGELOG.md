# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com/).


## [Unreleased]

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
