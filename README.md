# Textbringer Auto Revert

[![CI](https://github.com/yancya/textbringer-auto-revert/actions/workflows/ci.yml/badge.svg)](https://github.com/yancya/textbringer-auto-revert/actions/workflows/ci.yml)

A Textbringer plugin that automatically reverts buffers when files are modified externally.

## Installation

Install the gem by executing:

```bash
gem install textbringer-auto-revert
```

Or add it to your Gemfile:

```bash
bundle add textbringer-auto-revert
```

## Usage

**Auto-revert mode is enabled by default** when the plugin is loaded.

When a file is modified externally and the buffer has no unsaved changes, the buffer automatically reverts to the file's contents. This happens both after any command execution and periodically while the editor sits idle (every `:auto_revert_interval` seconds), so changes are picked up without touching the keyboard. The cursor position is preserved across reverts.

If the buffer has unsaved changes, it is never reverted; instead a warning (`Buffer has unsaved changes; file changed on disk`) is shown once per change. If the visited file disappears from disk (deleted or renamed), auto-revert warns once (`Auto-revert failed: ...`) and resumes automatically when the file comes back.

### Commands

| Command | Description |
|---------|-------------|
| `global_auto_revert_mode` | Toggle global auto-revert mode on/off |

### Disabling

To temporarily disable, run `M-x global_auto_revert_mode`.

To permanently disable, uninstall the gem or add to your Textbringer config:

```ruby
Textbringer::GlobalAutoRevertMode.disable
Textbringer::GlobalAutoRevertMode.enabled = false
```

### Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `:auto_revert_verbose` | Boolean | `true` | Show messages when a buffer is reverted, has unsaved changes while the file changed on disk, or its file went missing |
| `:auto_revert_interval` | Numeric (seconds) | `5` | How often the idle timer scans all file-backed buffers for external changes |

Set them in your `~/.textbringer.rb`:

```ruby
Textbringer::CONFIG[:auto_revert_verbose] = false
Textbringer::CONFIG[:auto_revert_interval] = 2
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yancya/textbringer-auto-revert.

## License

The gem is available as open source under the terms of the [WTFPL](http://www.wtfpl.net/).
