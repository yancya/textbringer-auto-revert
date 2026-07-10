# frozen_string_literal: true

require_relative "auto-revert/version"

module Textbringer
  CONFIG[:auto_revert_verbose] ||= true

  class GlobalAutoRevertMode < GlobalMinorMode
    POST_COMMAND_HOOK = -> {
      buffer = Buffer.current
      return unless buffer.file_name && !buffer.name.start_with?("*")

      begin
        unless buffer.file_modified?
          buffer[:auto_revert_warned] = false if buffer[:auto_revert_warned]
          buffer[:auto_revert_error_warned] = false if buffer[:auto_revert_error_warned]
          return
        end

        if !buffer.modified?
          if buffer.read_only?
            buffer.read_only_edit { buffer.revert }
          else
            buffer.revert
          end
          buffer[:auto_revert_warned] = false
          buffer[:auto_revert_error_warned] = false
          message("Reverted buffer from file") if CONFIG[:auto_revert_verbose]
        else
          if CONFIG[:auto_revert_verbose] && !buffer[:auto_revert_warned]
            message("Buffer has unsaved changes; file changed on disk")
            buffer[:auto_revert_warned] = true
          end
        end
      rescue StandardError => e
        # post_command_hook runs with remove_on_error: true, so an escaped
        # exception (e.g. Errno::ENOENT from file_modified? after the file
        # was deleted on disk) would silently unregister this hook for the
        # whole editor session. Warn once per buffer instead.
        if CONFIG[:auto_revert_verbose] && !buffer[:auto_revert_error_warned]
          message("Auto-revert failed: #{e.message}")
          buffer[:auto_revert_error_warned] = true
        end
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
