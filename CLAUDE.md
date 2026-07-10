# textbringer-auto-revert 開発メモ

## テスト実行

```
bundle exec rake test
```

テストは `test/test_helper.rb` の mock Textbringer で完結する（本物の textbringer / curses 不要）。mock は本物の挙動を再現している前提なので、textbringer 本体の API を触る変更をするときは、インストール済み gem のソース（`bundle show textbringer`）で実際の挙動を確認してから mock に反映すること。

## textbringer 本体の罠（一次ソースで確認済み・2026-07 時点 v26）

- `post_command_hook` は `run_hooks(:post_command_hook, remove_on_error: true)` で走る。**フック内で例外が漏れると、そのフックはエディタ全体から静かに除去される**。このプラグインのフック／スキャンが全例外を rescue しているのはこのため。外すな
- `GlobalMinorMode.inherited`（textbringer >= 15）がクラス名から toggle コマンド（`global_auto_revert_mode`）を**自動定義する**。プラグイン側で同名の `define_command` を書くと正しい自動定義を上書きして壊す（#9 で一度やらかした）
- `Buffer#file_modified?` は `File.mtime` 直呼びで、ファイルがディスクに無いと `Errno::ENOENT` を投げる
- `Buffer#revert` は `clear` + `set_contents` なので point が 0 に飛ぶ。point 復元は `goto_char`（範囲外で RangeError、マルチバイト文字の途中で ArgumentError）で行う
- idle 処理のイディオム: `background { }`（素の Thread）で sleep だけして、バッファ操作は `foreground { }`（= `next_tick`、self-pipe でアイドル中のイベントループを起こす）でメインループに寄せる。ロック不要

## 実機スモークテスト（tmux）

TUI の動作確認はヘッドレスでできる:

```
tmux new-session -d -s tb-smoke "bundle exec txtb /path/to/file"
tmux send-keys -t tb-smoke Escape x   # M-x
tmux capture-pane -t tb-smoke -p
tmux kill-session -t tb-smoke
```

idle revert の検証は「send-keys せずにファイルを外部から書き換えて interval+α 待って capture」でできる。

## リリース

`v*` タグを push すると `.github/workflows/release.yml`（RubyGems Trusted Publishing）が走る。手順: version.rb bump → CHANGELOG の Unreleased を版に付け替え → commit → タグ push。リリースはユーザーの明示 GO が必要。
