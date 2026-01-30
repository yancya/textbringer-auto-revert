# frozen_string_literal: true

require "test_helper"

class Textbringer::AutoRevertTest < Test::Unit::TestCase
  include Textbringer

  def setup
    @buffer = Textbringer::Buffer.new(name: "test.txt", file_name: "/tmp/test.txt")
    Textbringer::Buffer.current = @buffer
    Textbringer::Buffer.list = [@buffer]
    Textbringer.messages = []
    Textbringer::HOOKS.clear
    Textbringer::AutoRevert.global_mode = false
  end

  test "VERSION is defined" do
    assert do
      ::Textbringer::AutoRevert.const_defined?(:VERSION)
    end
  end

  test "global_auto_revert_mode enables global mode" do
    assert_equal false, Textbringer::AutoRevert.global_mode

    Textbringer::Commands.global_auto_revert_mode

    assert_equal true, Textbringer::AutoRevert.global_mode
    assert_includes Textbringer::HOOKS[:post_command_hook],
                    Textbringer::AutoRevert::POST_COMMAND_HOOK
  end

  test "global_auto_revert_mode toggles off" do
    Textbringer::Commands.global_auto_revert_mode  # enable
    Textbringer::Commands.global_auto_revert_mode  # disable

    assert_equal false, Textbringer::AutoRevert.global_mode
  end

  test "auto_revert_mode enables local mode for current buffer" do
    assert_nil @buffer[:auto_revert_mode]

    Textbringer::Commands.auto_revert_mode

    assert_equal true, @buffer[:auto_revert_mode]
    assert_includes Textbringer::HOOKS[:post_command_hook],
                    Textbringer::AutoRevert::POST_COMMAND_HOOK
  end

  test "auto_revert_mode toggles off" do
    Textbringer::Commands.auto_revert_mode  # enable
    Textbringer::Commands.auto_revert_mode  # disable

    assert_equal false, @buffer[:auto_revert_mode]
  end

  test "reverts buffer when file is modified and buffer is not modified" do
    Textbringer::Commands.global_auto_revert_mode
    @buffer.file_modified = true
    @buffer.modified = false

    Textbringer::AutoRevert::POST_COMMAND_HOOK.call

    assert_equal true, @buffer.reverted
    assert_includes Textbringer.messages, "Reverted buffer from file"
  end

  test "does not revert buffer when buffer has unsaved changes" do
    Textbringer::Commands.global_auto_revert_mode
    @buffer.file_modified = true
    @buffer.modified = true

    Textbringer::AutoRevert::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
    assert_includes Textbringer.messages, "Buffer has unsaved changes; file changed on disk"
  end

  test "does not revert when file is not modified" do
    Textbringer::Commands.global_auto_revert_mode
    @buffer.file_modified = false
    @buffer.modified = false

    Textbringer::AutoRevert::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end

  test "does not check when neither global nor local mode is enabled" do
    @buffer.file_modified = true
    @buffer.modified = false

    Textbringer::AutoRevert::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end

  test "skips special buffers starting with *" do
    @buffer.name = "*scratch*"
    @buffer.file_modified = true
    Textbringer::Commands.global_auto_revert_mode

    Textbringer::AutoRevert::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end

  test "skips buffers without file_name" do
    @buffer.file_name = nil
    @buffer.file_modified = true
    Textbringer::Commands.global_auto_revert_mode

    Textbringer::AutoRevert::POST_COMMAND_HOOK.call

    assert_equal false, @buffer.reverted
  end
end
