# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Mock Textbringer for testing without the actual dependency
module Textbringer
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

    attr_accessor :file_name, :name
    attr_reader :reverted, :properties

    def initialize(name: nil, file_name: nil)
      @name = name || "test"
      @file_name = file_name
      @modified = false
      @file_modified = false
      @reverted = false
      @properties = {}
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

    def file_modified?
      @file_modified
    end

    def file_modified=(val)
      @file_modified = val
    end

    def revert
      @reverted = true
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

  module Commands
    def self.define_command(name, doc: nil, &block)
      define_method(name, &block)
      module_function(name)
    end
  end

  class GlobalMinorMode
    class << self
      attr_accessor :enabled
      alias enabled? enabled
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
  end
end

require "textbringer/auto-revert"

require "test/unit"
