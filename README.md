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

### Commands

| Command | Description |
|---------|-------------|
| `auto_revert_mode` | Toggle auto-revert mode for the current buffer |
| `global_auto_revert_mode` | Toggle global auto-revert mode for all buffers |

### Example

1. Open a file in Textbringer (`C-x C-f`)
2. Enable global auto-revert mode: `M-x global_auto_revert_mode`
3. Edit the file externally (e.g., in another terminal)
4. Execute any command in Textbringer (e.g., `C-n`)
5. The buffer will automatically revert to the file's contents

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
