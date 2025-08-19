#!/usr/bin/env bash
set -euo pipefail

# Fetch external repositories used by integration tests on demand.
# This script shallow-clones fixed refs (or branches) into tests/repositories/.
# Usage:
#   scripts/fetch-fixtures.sh [--no-deepspeech] [--no-pdfjs] [--no-serde]
# Env overrides:
#   DEEPSPEECH_REF=commit-or-branch
#   PDFJS_REF=commit-or-branch
#   SERDE_REF=commit-or-branch

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
FIX_DIR="$ROOT_DIR/tests/repositories"

mkdir -p "$FIX_DIR"

clone_repo() {
  local name="$1" url="$2" ref="$3"
  local dest="$FIX_DIR/$name"
  if [ -d "$dest/.git" ]; then
    echo "[skip] $name already present: $dest"
    return 0
  fi
  echo "[clone] $name -> $dest (ref: $ref)"
  git init "$dest" >/dev/null
  git -C "$dest" remote add origin "$url"
  # Use shallow, blobless, sparse-friendly fetch
  git -C "$dest" fetch --depth 1 --filter=blob:none origin "$ref"
  git -C "$dest" checkout FETCH_HEAD
}

# Use stable tags/branches by default; override via env as needed.
# Known stable refs (adjust over time):
#   DeepSpeech: v0.9.3
#   pdf.js: v3.11.174
#   serde: v1.0.208
DEEPSPEECH_REF="${DEEPSPEECH_REF:-v0.9.3}"
PDFJS_REF="${PDFJS_REF:-v3.11.174}"
SERDE_REF="${SERDE_REF:-v1.0.208}"

NO_DEEPSPEECH=0
NO_PDFJS=0
NO_SERDE=0
for arg in "$@"; do
  case "$arg" in
    --no-deepspeech) NO_DEEPSPEECH=1 ;;
    --no-pdfjs) NO_PDFJS=1 ;;
    --no-serde) NO_SERDE=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

[ "$NO_DEEPSPEECH" -eq 1 ] || clone_repo "DeepSpeech" "https://github.com/mozilla/DeepSpeech" "$DEEPSPEECH_REF"
[ "$NO_PDFJS" -eq 1 ] || clone_repo "pdf.js" "https://github.com/mozilla/pdf.js" "$PDFJS_REF"
[ "$NO_SERDE" -eq 1 ] || clone_repo "serde" "https://github.com/serde-rs/serde" "$SERDE_REF"

echo "Done."
