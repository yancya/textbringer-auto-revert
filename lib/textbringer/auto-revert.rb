# frozen_string_literal: true

require_relative "auto-revert/version"

module Textbringer
  CONFIG[:auto_revert_verbose] ||= true
  CONFIG[:auto_revert_interval] ||= 5

  class GlobalAutoRevertMode < GlobalMinorMode
    # Check one buffer and revert it if the file changed on disk.
    # Shared by the post-command hook and the idle timer, and must never
    # raise: post_command_hook runs with remove_on_error: true, so an
    # escaped exception (e.g. Errno::ENOENT from file_modified? after the
    # file was deleted on disk) would silently unregister the hook for the
    # whole editor session. Warn once per buffer instead.
    def self.check_buffer(buffer)
      return unless buffer.file_name && !buffer.name.start_with?("*")

      unless buffer.file_modified?
        buffer[:auto_revert_warned] = false if buffer[:auto_revert_warned]
        buffer[:auto_revert_error_warned] = false if buffer[:auto_revert_error_warned]
        return
      end

      if !buffer.modified?
        saved_point = buffer.point
        if buffer.read_only?
          buffer.read_only_edit { buffer.revert }
        else
          buffer.revert
        end
        restore_point(buffer, saved_point)
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
      if CONFIG[:auto_revert_verbose] && !buffer[:auto_revert_error_warned]
        message("Auto-revert failed: #{e.message}")
        buffer[:auto_revert_error_warned] = true
      end
    end

    def self.check_all_buffers
      Buffer.list.each do |buffer|
        check_buffer(buffer)
      end
    end

    POST_COMMAND_HOOK = -> {
      GlobalAutoRevertMode.check_buffer(Buffer.current)
    }

    # Buffer#revert resets point to 0; put it back where it was, clamped to
    # the new buffer size. The reverted content may have shifted so the old
    # byte offset can land inside a multi-byte character (goto_char raises
    # ArgumentError) — step back until it sticks.
    def self.restore_point(buffer, pos)
      pos = pos.clamp(0, buffer.size)
      begin
        buffer.goto_char(pos)
      rescue ArgumentError
        pos -= 1
        retry if pos >= 0
      rescue RangeError
        # size changed between clamp and goto_char; stay at 0
      end
    end

    class << self
      attr_reader :timer_thread
    end

    # Pick up files changed while the editor sits idle: a background thread
    # sleeps, then schedules the scan on the main event loop via foreground
    # (which wakes the idle event loop through its self-pipe). All buffer
    # access happens on the main loop, so no locking is needed.
    def self.start_timer
      return if @timer_thread&.alive?
      @timer_thread = background do
        loop do
          sleep(CONFIG[:auto_revert_interval])
          # The enabled? guard covers a scan already queued when the mode
          # is disabled: the sleeper thread dies, but the queued block
          # still runs on the main loop.
          foreground do
            GlobalAutoRevertMode.check_all_buffers if GlobalAutoRevertMode.enabled?
          end
        end
      end
    end

    # Thread#kill only stops the sleeper; a scan it already queued via
    # foreground may still run once afterwards, which the enabled? guard
    # above turns into a no-op. The join keeps a rapid disable→enable from
    # seeing the dying thread as alive and skipping the restart.
    def self.stop_timer
      if @timer_thread
        @timer_thread.kill
        @timer_thread.join(1)
        @timer_thread = nil
      end
    end

    def self.enable
      add_hook(:post_command_hook, POST_COMMAND_HOOK)
      start_timer
      message("Global auto-revert mode enabled")
    end

    def self.disable
      remove_hook(:post_command_hook, POST_COMMAND_HOOK)
      stop_timer
      message("Global auto-revert mode disabled")
    end
  end

  # The global_auto_revert_mode toggle command is auto-defined by
  # GlobalMinorMode.inherited (textbringer >= 15) — do not redefine it here.

  # Enable by default on plugin load
  GlobalAutoRevertMode.enable
  GlobalAutoRevertMode.enabled = true
end
