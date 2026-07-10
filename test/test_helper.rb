# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Mock Textbringer for testing without the actual dependency
module Textbringer
  class EditorError < StandardError; end
  CONFIG = {} unless defined?(CONFIG)
  HOOKS = Hash.new { |h, k| h[k] = [] } unless defined?(HOOKS)

  class << self
    attr_accessor :messages
  end
  self.messages = []

  class Buffer
    @current = nil
    @list = []

    class << self
      attr_accessor :current, :list
    end

    attr_accessor :file_name, :name, :read_only, :file_missing, :revert_error,
                  :size
    attr_reader :reverted, :properties, :point

    def initialize(name: nil, file_name: nil)
      @name = name || "test"
      @file_name = file_name
      @modified = false
      @file_modified = false
      @reverted = false
      @read_only = false
      @file_missing = false
      @revert_error = nil
      @properties = {}
      @point = 0
      @size = 100
      @invalid_positions = nil
    end

    attr_accessor :invalid_positions # byte offsets that fall mid-character

    # Mirrors real Buffer#goto_char: raises RangeError when out of range,
    # ArgumentError when the position is in the middle of a character.
    def goto_char(pos)
      raise RangeError, "Out of buffer" if pos < 0 || pos > @size
      if @invalid_positions&.include?(pos)
        raise ArgumentError, "Position is in the middle of a character"
      end
      @point = pos
    end

    def read_only?
      @read_only
    end

    def read_only_edit
      old_read_only = @read_only
      @read_only = false
      yield
    ensure
      @read_only = old_read_only
    end

    def [](key)
      @properties[key]
    end

    def []=(key, value)
      @properties[key] = value
    end

    def modified?
      @modified
    end

    def modified=(val)
      @modified = val
    end

    # Real Buffer#file_modified? calls File.mtime, which raises
    # Errno::ENOENT when the visited file was deleted/renamed on disk.
    def file_modified?
      raise Errno::ENOENT, @file_name if @file_missing
      @file_modified
    end

    def file_modified=(val)
      @file_modified = val
    end

    # Real Buffer#revert clears the buffer, which resets point to 0.
    def revert
      raise EditorError, "Read-only buffer" if @read_only
      raise @revert_error if @revert_error
      @reverted = true
      @point = 0
    end
  end

  module_function

  def add_hook(name, hook)
    HOOKS[name] << hook unless HOOKS[name].include?(hook)
  end

  def remove_hook(name, hook)
    HOOKS[name].delete(hook)
  end

  def message(msg)
    Textbringer.messages << msg
  end

  # Real Utils#background starts a plain Thread.
  def background(&block)
    Thread.start(&block)
  end

  # Real Utils#foreground queues the block onto the main event loop; the
  # mock runs it synchronously, which is equivalent for these tests.
  def foreground(&block)
    block.call
  end

  module Commands
    def self.define_command(name, doc: nil, &block)
      define_method(name, &block)
      module_function(name)
    end
  end

  def self.define_command(name, doc: nil, &block)
    Commands.define_command(name, doc: doc, &block)
  end

  class GlobalMinorMode
    class << self
      attr_accessor :enabled
      alias enabled? enabled
    end

    # Real GlobalMinorMode.inherited (textbringer >= 15) auto-defines a
    # toggle command named after the subclass.
    def self.inherited(child)
      super
      child.instance_variable_set(:@enabled, false)
      base_name = child.name.slice(/[^:]*\z/)
      command_name = base_name.sub(/\A[A-Z]/) { |s| s.downcase }
                              .gsub(/(?<=[a-z])([A-Z])/) { "_#{$1.downcase}" }
      Textbringer.define_command(command_name.intern) do |arg = nil|
        enable =
          case arg
          when true, false
            next if child.enabled? == arg
            arg
          when nil
            !child.enabled?
          else
            raise ArgumentError, "wrong argument #{arg.inspect} (expected true, false, or nil)"
          end
        if enable
          child.enable
          child.enabled = true
        else
          child.disable
          child.enabled = false
        end
      end
    end

    def self.add_hook(name, hook)
      Textbringer.add_hook(name, hook)
    end

    def self.remove_hook(name, hook)
      Textbringer.remove_hook(name, hook)
    end

    def self.message(msg)
      Textbringer.message(msg)
    end

    def self.background(&block)
      Textbringer.background(&block)
    end

    def self.foreground(&block)
      Textbringer.foreground(&block)
    end
  end
end

require "textbringer/auto-revert"

require "test/unit"
