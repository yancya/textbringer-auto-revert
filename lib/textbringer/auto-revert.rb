# frozen_string_literal: true

require_relative "auto-revert/version"

module Textbringer
  CONFIG[:auto_revert_verbose] = true

  class GlobalAutoRevertMode < GlobalMinorMode
    POST_COMMAND_HOOK = -> {
      buffer = Buffer.current
      return unless buffer.file_name && !buffer.name.start_with?("*")
      return unless buffer.file_modified?

      if !buffer.modified?
        buffer.revert
        message("Reverted buffer from file") if CONFIG[:auto_revert_verbose]
      else
        message("Buffer has unsaved changes; file changed on disk")
      end
    }

    def self.enable
      add_hook(:post_command_hook, POST_COMMAND_HOOK)
      message("Global auto-revert mode enabled")
    end

    def self.disable
      remove_hook(:post_command_hook, POST_COMMAND_HOOK)
      message("Global auto-revert mode disabled")
    end
  end

  define_command(:global_auto_revert_mode, doc: "Toggle global auto-revert mode.") do
    GlobalAutoRevertMode.toggle
  end

  # Enable by default on plugin load
  GlobalAutoRevertMode.enable
  GlobalAutoRevertMode.enabled = true
end
