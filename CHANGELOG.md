# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Timer-based idle revert: a background thread scans all file-backed buffers
  every `CONFIG[:auto_revert_interval]` seconds (default 5), so external
  changes are picked up without any command execution (#6)
- `CONFIG[:auto_revert_interval]` configuration key (#6)

### Fixed

- A file deleted or renamed on disk silently killed global auto-revert mode
  for the whole editor session; it now warns once per buffer and resumes when
  the file comes back (#4)
- Cursor position (point) is preserved across auto-revert instead of jumping
  to the beginning of the buffer (#5)
- `M-x global_auto_revert_mode` raised `NoMethodError`; the plugin no longer
  overrides the toggle command that textbringer auto-defines (#9)

### Changed

- Minimum supported textbringer version is now 15 (the release that
  introduced `GlobalMinorMode`, which this plugin has always required) (#9)

## [0.3.4] - 2026-02-06

### Changed

- Refined auto-revert verbosity: warn once (not repeatedly) when a buffer has
  unsaved changes while the file changed on disk

## [0.3.3] - 2026-01-30

### Fixed

- Support auto-revert for read-only buffers

## [0.3.2] - 2026-01-30

### Added

- lefthook pre-commit test hook (development only)

## [0.3.1] - 2026-01-30

### Added

- `global_auto_revert_mode` command definition

## [0.3.0] - 2026-01-30

### Changed

- Auto-revert mode is enabled by default on plugin load

## [0.2.0] - 2026-01-30

### Fixed

- Use `GlobalMinorMode` for proper hook management

## [0.1.0] - 2026-01-30

### Added

- Initial implementation: revert unmodified buffers after command execution
  when the visited file changed on disk

[Unreleased]: https://github.com/yancya/textbringer-auto-revert/compare/v0.3.4...HEAD
[0.3.4]: https://github.com/yancya/textbringer-auto-revert/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/yancya/textbringer-auto-revert/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/yancya/textbringer-auto-revert/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/yancya/textbringer-auto-revert/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/yancya/textbringer-auto-revert/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yancya/textbringer-auto-revert/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yancya/textbringer-auto-revert/releases/tag/v0.1.0
