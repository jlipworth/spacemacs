# Agent instructions

Read `CLAUDE.md` for repository structure, conventions, and test commands.

## Interactive Emacs testing

- Never restart, kill, or automate the user's primary Emacs instance.
- Use batch/ERT tests when they are sufficient. Use an isolated GUI instance
  when a change needs full startup, restart, frame, font, image, color, or
  other interactive verification.
- If the current checkout is already a task-specific worktree separate from
  `~/.emacs.d`, launch the playground from that checkout:

  ```sh
  open -na Emacs --args --init-directory="$PWD"
  ```

- If the current checkout is the live `~/.emacs.d`, first create a uniquely
  named detached worktree at the commit to test, then use that worktree as the
  init directory. Do not use a shared fixed playground path when concurrent
  agents may be working.
- Treat `~/.spacemacs` and the `GNU_files` repository as read-only unless the
  task explicitly includes changing them. If they must change, test with a
  separate GNU-files worktree rather than the live checkout.
- Identify the playground process by its `--init-directory` argument. Stop
  only that process, and remove disposable worktrees after testing.

Runtime state such as `elpa/`, `.cache/`, and `eln-cache/` is intentionally
created beneath the playground's init directory, keeping it separate from the
user's active Emacs state.
