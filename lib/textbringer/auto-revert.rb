# frozen_string_literal: true

require_relative "auto-revert/version"

module Textbringer
  CONFIG[:auto_revert_verbose] = true

  module AutoRevert
    @global_mode = false

    class << self
      attr_accessor :global_mode
    end

    POST_COMMAND_HOOK = -> {
      return unless AutoRevert.should_check?

      buffer = Buffer.current
      return unless AutoRevert.buffer_eligible?(buffer)
      return unless buffer.file_modified?

      # バッファが未変更なら自動revert
      if !buffer.modified?
        buffer.revert
        Textbringer.message("Reverted buffer from file") if CONFIG[:auto_revert_verbose]
      else
        Textbringer.message("Buffer has unsaved changes; file changed on disk")
      end
    }

    def self.should_check?
      @global_mode || Buffer.current[:auto_revert_mode]
    end

    def self.buffer_eligible?(buffer)
      buffer.file_name && !buffer.name.start_with?("*")
    end

    def self.enable_global
      @global_mode = true
      Textbringer.add_hook(:post_command_hook, POST_COMMAND_HOOK)
      Textbringer.message("Global auto-revert mode enabled")
    end

    def self.disable_global
      @global_mode = false
      # ローカルモードが有効なバッファがなければフック削除
      unless Buffer.list.any? { |b| b[:auto_revert_mode] }
        Textbringer.remove_hook(:post_command_hook, POST_COMMAND_HOOK)
      end
      Textbringer.message("Global auto-revert mode disabled")
    end
  end

  module Commands
    define_command(:auto_revert_mode,
      doc: "Toggle auto-revert mode for the current buffer.") do
      buffer = Buffer.current
      if buffer[:auto_revert_mode]
        buffer[:auto_revert_mode] = false
        Textbringer.message("Auto-revert mode disabled in this buffer")
      else
        buffer[:auto_revert_mode] = true
        # フックがなければ追加
        unless HOOKS[:post_command_hook].include?(AutoRevert::POST_COMMAND_HOOK)
          Textbringer.add_hook(:post_command_hook, AutoRevert::POST_COMMAND_HOOK)
        end
        Textbringer.message("Auto-revert mode enabled in this buffer")
      end
    end

    define_command(:global_auto_revert_mode,
      doc: "Toggle global auto-revert mode for all buffers.") do
      if AutoRevert.global_mode
        AutoRevert.disable_global
      else
        AutoRevert.enable_global
      end
    end
  end
end
