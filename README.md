# Textbringer Auto Revert

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

When a file is modified externally and the buffer has no unsaved changes, the buffer will automatically revert to the file's contents after any command execution.

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

| Key | Default | Description |
|-----|---------|-------------|
| `:auto_revert_verbose` | `true` | Show message when buffer is reverted |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yancya/textbringer-auto-revert.

## License

The gem is available as open source under the terms of the [WTFPL](http://www.wtfpl.net/).
