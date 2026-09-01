#!/usr/bin/env bash
#
# repo-cloner — interactively pick GitHub repositories and clone them into
# per-project folders.
#
# Repositories are discovered live through the GitHub CLI, so newly created
# ones show up without touching this script. Already-cloned repositories are
# detected and excluded from the picker, which makes the script safe to re-run.
#
# Configuration lives outside this repository. See groups.example.conf.
#
# Usage:
#   clone-repos.sh [--dest DIR] [--config FILE] [--dry-run]
#
# Picker selection: REPO_CLONER_PICKER=gum|fzf (auto-detected by default)
#
set -uo pipefail

CONFIG="${REPO_CLONER_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/repo-cloner/groups.conf}"
DEST="${REPO_CLONER_DEST:-$PWD}"
DRY_RUN=0

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)    DEST="${2:?--dest requires a directory}"; shift 2 ;;
    --config)  CONFIG="${2:?--config requires a file}";  shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown argument: $1" >&2; usage 1 ;;
  esac
done

command -v gh >/dev/null || { echo "gh (GitHub CLI) is required" >&2; exit 1; }

PICKER="${REPO_CLONER_PICKER:-}"
if [ -n "$PICKER" ]; then
  command -v "$PICKER" >/dev/null || { echo "requested picker not found: $PICKER" >&2; exit 1; }
elif command -v gum >/dev/null; then PICKER=gum
elif command -v fzf >/dev/null; then PICKER=fzf
else echo "either gum or fzf is required for the interactive picker" >&2; exit 1
fi

if [ ! -f "$CONFIG" ]; then
  cat >&2 <<EOF
No configuration found at: $CONFIG

Create it with one line per group:

  # <folder>|<owner>|<name filter regex, empty = every repo>
  work|acme-inc|
  client|my-user|clientname

See groups.example.conf in this directory for a fuller example.
EOF
  exit 1
fi

mkdir -p "$DEST" && cd "$DEST" || { echo "cannot use destination: $DEST" >&2; exit 1; }

# Each record is: DISPLAY \t OWNER/NAME \t FOLDER
RECORDS=() ; SKIPPED=()

echo "Reading $CONFIG" >&2
echo "Fetching repository inventory from GitHub..." >&2

while IFS='|' read -r folder owner filter; do
  case "${folder// /}" in ''|'#'*) continue ;; esac
  folder="${folder// /}"; owner="${owner// /}"; filter="${filter# }"; filter="${filter% }"
  [ -z "$owner" ] && { echo "skipping malformed line for folder '$folder': no owner" >&2; continue; }

  # Build the jq selector. An empty filter keeps every non-archived repo.
  if [ -n "$filter" ]; then
    select="select(.name|test(\"${filter//\"/\\\"}\";\"i\")) |"
  else
    select=""
  fi

  while IFS=$'\t' read -r name lang updated; do
    [ -z "$name" ] && continue
    if [ -d "$folder/$name/.git" ]; then
      SKIPPED+=("$folder/$name")
      continue
    fi
    RECORDS+=("$(printf '%-10s %-34s %-12s %s\t%s/%s\t%s' \
      "$folder" "$name" "$lang" "$updated" "$owner" "$name" "$folder")")
  done < <(
    gh repo list "$owner" --limit 500 \
      --json name,primaryLanguage,updatedAt,isArchived \
      -q ".[] | select(.isArchived==false) | $select \"\(.name)\t\(.primaryLanguage.name // \"-\")\t\(.updatedAt[0:10])\"" \
      2>/dev/null
  )
done < "$CONFIG"

if [ "${#SKIPPED[@]}" -gt 0 ]; then
  printf 'Already cloned (%d):\n' "${#SKIPPED[@]}"
  printf '  %s\n' "${SKIPPED[@]}" | sort
  echo
fi

if [ "${#RECORDS[@]}" -eq 0 ]; then
  echo "Nothing left to clone."
  exit 0
fi

HEADER="space toggles · enter confirms · esc aborts"
if [ "$PICKER" = gum ]; then
  # gum wants "label|value"; the value keeps slug and folder tab-separated.
  mapfile -t PICKED < <(
    while IFS=$'\t' read -r display slug folder; do
      printf '%s|%s\t%s\n' "$display" "$slug" "$folder"
    done < <(printf '%s\n' "${RECORDS[@]}") \
      | gum choose --no-limit --height 24 --label-delimiter='|' --header="$HEADER"
  )
else
  mapfile -t PICKED < <(
    printf '%s\n' "${RECORDS[@]}" \
      | fzf --multi --with-nth=1 --delimiter=$'\t' --header="tab toggles · enter confirms" \
      | cut -f2,3
  )
fi

[ "${#PICKED[@]}" -eq 0 ] && { echo "No repositories selected."; exit 0; }

printf '\n%s %d repositories into %s\n\n' \
  "$([ "$DRY_RUN" -eq 1 ] && echo 'Would clone' || echo 'Cloning')" "${#PICKED[@]}" "$DEST"

ok=0; fail=0
for entry in "${PICKED[@]}"; do
  [ -z "$entry" ] && continue
  IFS=$'\t' read -r slug folder <<<"$entry"
  target="$folder/${slug##*/}"
  printf '  %-48s ' "$target"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry run)"; ok=$((ok+1)); continue
  fi
  mkdir -p "$folder"
  if out=$(gh repo clone "$slug" "$target" -- --quiet 2>&1); then
    echo "ok"; ok=$((ok+1))
  else
    echo "FAILED"; printf '%s\n' "$out" | sed 's/^/      /'; fail=$((fail+1))
  fi
done

printf '\nDone: %d cloned, %d failed.\n' "$ok" "$fail"
[ "$fail" -eq 0 ]
