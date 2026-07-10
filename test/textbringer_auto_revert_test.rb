# frozen_string_literal: true

require "test_helper"

class Textbringer::GlobalAutoRevertModeTest < Test::Unit::TestCase
  include Textbringer

  def setup
    @buffer = Textbringer::Buffer.new(name: "test.txt", file_name: "/tmp/test.txt")
    Textbringer::Buffer.current = @buffer
    Textbringer::Buffer.list = [@buffer]
    Textbringer.messages = []
    Textbringer::HOOKS.clear
    Textbringer::CONFIG[:auto_revert_verbose] = true
    stop_timer
  end

  def teardown
    stop_timer
    Textbringer::CONFIG[:auto_revert_interval] = 5
  end

  private def stop_timer
    mode = Textbringer::GlobalAutoRevertMode
    mode.stop_timer if mode.respond_to?(:stop_timer)
  end

  test "VERSION is defined" do
    assert do
      ::Textbringer::AutoRevert.const_defined?(:VERSION)
    end
  end

  test "enable adds hook and shows message" do
    Textbringer::GlobalAutoRevertMode.enable

    assert_includes Textbringer::HOOKS[:post_command_hook],
                    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK
    assert_includes Textbringer.messages, "Global auto-revert mode enabled"
  end

  test "disable removes hook and shows message" do
    Textbringer::GlobalAutoRevertMode.enable
    Textbringer::GlobalAutoRevertMode.disable

    refute_includes Textbringer::HOOKS[:post_command_hook],
                    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK
    assert_includes Textbringer.messages, "Global auto-revert mode disabled"
  end

  test "reverts buffer when file is modified and buffer is not modified" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.modified = false

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal true, @buffer.reverted
    assert_includes Textbringer.messages, "Reverted buffer from file"
  end

  test "does not revert buffer when buffer has unsaved changes" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.modified = true

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
    assert_includes Textbringer.messages, "Buffer has unsaved changes; file changed on disk"
  end

  test "warns only once while file remains modified and buffer has changes" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.modified = true

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    warnings = Textbringer.messages.count { |msg| msg == "Buffer has unsaved changes; file changed on disk" }
    assert_equal 1, warnings
  end

  test "suppresses warnings when verbose is disabled" do
    Textbringer::GlobalAutoRevertMode.enable
    Textbringer::CONFIG[:auto_revert_verbose] = false
    @buffer.file_modified = true
    @buffer.modified = true

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    refute_includes Textbringer.messages, "Buffer has unsaved changes; file changed on disk"
  end

  test "does not revert when file is not modified" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = false
    @buffer.modified = false

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end

  test "skips special buffers starting with *" do
    @buffer.name = "*scratch*"
    @buffer.file_modified = true
    Textbringer::GlobalAutoRevertMode.enable

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end

  test "skips buffers without file_name" do
    @buffer.file_name = nil
    @buffer.file_modified = true
    Textbringer::GlobalAutoRevertMode.enable

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end

  test "reverts read-only buffer when file is modified" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.modified = false
    @buffer.read_only = true

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal true, @buffer.reverted
    assert_equal true, @buffer.read_only?, "Buffer should remain read-only after revert"
  end

  test "does not raise when the visited file is missing on disk" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_missing = true

    assert_nothing_raised do
      Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    end
    assert_equal false, @buffer.reverted
  end

  test "warns only once while the file remains missing" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_missing = true

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    warnings = Textbringer.messages.grep(/Auto-revert failed/)
    assert_equal 1, warnings.size
  end

  test "auto-revert works again and warns anew after the file reappears" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_missing = true
    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    @buffer.file_missing = false
    @buffer.file_modified = true
    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    assert_equal true, @buffer.reverted

    @buffer.file_missing = true
    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    warnings = Textbringer.messages.grep(/Auto-revert failed/)
    assert_equal 2, warnings.size
  end

  test "does not raise when revert itself fails (file deleted mid-revert)" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.revert_error = Errno::ENOENT.new("/tmp/test.txt")

    assert_nothing_raised do
      Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    end
  end

  test "preserves point across auto-revert" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.goto_char(42)

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_equal true, @buffer.reverted
    assert_equal 42, @buffer.point
  end

  test "clamps point to buffer size when the file shrank below old point" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.goto_char(90)
    @buffer.size = 10 # reverted content is shorter than old point

    assert_nothing_raised do
      Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    end
    assert_equal true, @buffer.reverted
    assert_equal 10, @buffer.point
  end

  test "steps back to a character boundary when old point lands mid-character" do
    Textbringer::GlobalAutoRevertMode.enable
    @buffer.file_modified = true
    @buffer.goto_char(42)
    @buffer.invalid_positions = [42, 41] # content shifted; 42 is now inside a multi-byte char

    assert_nothing_raised do
      Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call
    end
    assert_equal true, @buffer.reverted
    assert_equal 40, @buffer.point
  end

  test "suppresses missing-file warnings when verbose is disabled" do
    Textbringer::GlobalAutoRevertMode.enable
    Textbringer::CONFIG[:auto_revert_verbose] = false
    @buffer.file_missing = true

    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK.call

    assert_empty Textbringer.messages.grep(/Auto-revert failed/)
  end

  test "default auto_revert_interval is 5 seconds" do
    assert_equal 5, Textbringer::CONFIG[:auto_revert_interval]
  end

  test "check_all_buffers reverts every stale file-backed buffer, not just the current one" do
    other = Textbringer::Buffer.new(name: "other.txt", file_name: "/tmp/other.txt")
    special = Textbringer::Buffer.new(name: "*scratch*", file_name: "/tmp/scratch")
    fileless = Textbringer::Buffer.new(name: "no-file")
    [@buffer, other, special, fileless].each { |b| b.file_modified = true }
    Textbringer::Buffer.list = [@buffer, other, special, fileless]

    Textbringer::GlobalAutoRevertMode.check_all_buffers

    assert_equal true, @buffer.reverted
    assert_equal true, other.reverted
    assert_equal false, special.reverted
    assert_equal false, fileless.reverted
  end

  test "a broken buffer does not stop the scan of the remaining buffers" do
    broken = Textbringer::Buffer.new(name: "broken.txt", file_name: "/tmp/broken.txt")
    broken.file_missing = true
    ok = Textbringer::Buffer.new(name: "ok.txt", file_name: "/tmp/ok.txt")
    ok.file_modified = true
    Textbringer::Buffer.list = [broken, ok]

    assert_nothing_raised do
      Textbringer::GlobalAutoRevertMode.check_all_buffers
    end
    assert_equal true, ok.reverted
  end

  test "enable starts the idle timer thread and disable stops it" do
    Textbringer::GlobalAutoRevertMode.enable
    thread = Textbringer::GlobalAutoRevertMode.timer_thread
    assert_not_nil thread
    assert_true thread.alive?

    Textbringer::GlobalAutoRevertMode.disable
    thread.join(1)
    assert_false thread.alive?
    assert_nil Textbringer::GlobalAutoRevertMode.timer_thread
  end

  test "enabling twice keeps exactly one timer thread" do
    Textbringer::GlobalAutoRevertMode.enable
    first = Textbringer::GlobalAutoRevertMode.timer_thread
    Textbringer::GlobalAutoRevertMode.enable

    assert_same first, Textbringer::GlobalAutoRevertMode.timer_thread
  end

  test "global_auto_revert_mode command toggles the mode without raising" do
    Textbringer::GlobalAutoRevertMode.enable
    Textbringer::GlobalAutoRevertMode.enabled = true

    assert_nothing_raised do
      Textbringer::Commands.global_auto_revert_mode
    end
    assert_false Textbringer::GlobalAutoRevertMode.enabled?
    refute_includes Textbringer::HOOKS[:post_command_hook],
                    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK

    Textbringer::Commands.global_auto_revert_mode
    assert_true Textbringer::GlobalAutoRevertMode.enabled?
    assert_includes Textbringer::HOOKS[:post_command_hook],
                    Textbringer::GlobalAutoRevertMode::POST_COMMAND_HOOK
  end

  test "idle timer reverts a stale buffer without any command execution" do
    Textbringer::CONFIG[:auto_revert_interval] = 0.01
    @buffer.file_modified = true

    Textbringer::GlobalAutoRevertMode.enable
    Textbringer::GlobalAutoRevertMode.enabled = true
    deadline = Time.now + 2
    sleep 0.01 until @buffer.reverted || Time.now > deadline

    assert_equal true, @buffer.reverted
  end

  test "idle scan is a no-op while the mode is flagged off" do
    Textbringer::CONFIG[:auto_revert_interval] = 0.01
    @buffer.file_modified = true

    Textbringer::GlobalAutoRevertMode.enable
    Textbringer::GlobalAutoRevertMode.enabled = false
    sleep 0.1

    assert_equal false, @buffer.reverted
  ensure
    Textbringer::GlobalAutoRevertMode.enabled = true
  end
end
