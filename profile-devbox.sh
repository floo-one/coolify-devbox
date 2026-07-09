# Auto-attach to the persistent 'main' tmux session on interactive SSH login.
# Shipped as /etc/profile.d/99-devbox-tmux.sh, so a freshly deployed box behaves
# as documented without any per-volume setup.
#
# Guards: only for an interactive shell with a real TTY (SSH_TTY set) that isn't
# already inside tmux. VS Code / Cursor Remote-SSH and `ssh devbox <cmd>` allocate
# no TTY, so they are deliberately left alone (dropping them into tmux breaks them).
case "$-" in
  *i*)
    if [ -z "${TMUX:-}" ] && [ -n "${SSH_TTY:-}" ] && command -v tmux >/dev/null 2>&1; then
      # First-time setup wizard (git identity / gh / claude). Runs until every
      # item is done or the user dismisses it; then never again automatically.
      if [ ! -f "$HOME/.local/state/devbox/setup-done" ]; then
        devbox-setup || true
      fi
      workstation >/dev/null 2>&1 || true
      exec tmux new-session -A -s main
    fi
    ;;
esac
