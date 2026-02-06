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
end
