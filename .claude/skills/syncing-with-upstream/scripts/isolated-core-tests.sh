#!/bin/sh
# Keep batch Spacemacs startup away from the user's package/cache directories.
set -eu
repo=$(git rev-parse --show-toplevel)
real_emacs=$(command -v emacs)
runtime=$(mktemp -d "${TMPDIR:-/tmp}/spacemacs-core-tests.XXXXXX")
export SPACEMACS_TEST_RUNTIME="$runtime" SPACEMACS_TEST_EMACS="$real_emacs"
mkdir "$runtime/bin"
cat > "$runtime/bin/emacs" <<'WRAPPER'
#!/bin/sh
exec "$SPACEMACS_TEST_EMACS" -Q --eval '
(progn
  (setq user-emacs-directory
        (file-name-as-directory (getenv "SPACEMACS_TEST_RUNTIME")))
  (when (fboundp (quote startup-redirect-eln-cache))
    (startup-redirect-eln-cache
     (expand-file-name "eln-cache/" user-emacs-directory))))' "$@"
WRAPPER
chmod +x "$runtime/bin/emacs"
printf 'Isolated test runtime (retained for inspection): %s\n' "$runtime"
# Optional seed must be an independent copy, never a symlink to live ELPA.
if [ -n "${SPACEMACS_TEST_ELPA_SEED:-}" ]; then
  python3 -c 'import shutil,sys; shutil.copytree(sys.argv[1], sys.argv[2], ignore=shutil.ignore_patterns("elpa"))' \
    "$SPACEMACS_TEST_ELPA_SEED" "$runtime/elpa"
fi
PATH="$runtime/bin:$PATH" make -C "$repo/tests/core" "${@:-test}"
