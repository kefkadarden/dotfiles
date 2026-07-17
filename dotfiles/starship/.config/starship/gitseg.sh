#!/usr/bin/env bash
# gitseg.sh - git segment helper for Starship, mirroring the oh-my-posh git block.
#   gitseg.sh state    -> clean | dirty | ahead | behind | diverged  (exit 1 if not a repo)
#   gitseg.sh render   -> "<provider> <branch> <upstream-status> <changes>"
# Icons are Nerd Font codepoints written as \uXXXX (bash $'...' expands them).
# Swap any codepoint using https://www.nerdfonts.com/cheat-sheet
set -o pipefail

ICON_BRANCH=$'\xee\x82\xa0'      # branch
ICON_AZURE=$'\xee\xaf\xa8'       # azure devops
ICON_GITHUB=$'\xef\x82\x9b'      # github
ICON_GITLAB=$'\xef\x8a\x96'      # gitlab
ICON_BITBUCKET=$'\xef\x85\xb1'   # bitbucket
ICON_GIT=$'\xee\x9c\x82'         # generic git
ICON_EQUAL=$'\xe2\x89\xa1'       # up to date (=)
ICON_AHEAD=$'\xe2\x87\xa1'       # ahead
ICON_BEHIND=$'\xe2\x87\xa3'      # behind
ICON_CHANGED=$'\xef\x81\x84'     # working-tree changes (pencil)
ICON_STAGED=$'\xef\x81\x86'      # staged changes (check box)
ICON_STASH=$'\xef\x80\x9c'       # stash

in_repo()      { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }
has_upstream() { git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; }

provider_icon() {
  local url; url=$(git remote get-url origin 2>/dev/null)
  case "$url" in
    *dev.azure*|*visualstudio*|*azure*) printf '%s' "$ICON_AZURE" ;;
    *github*)    printf '%s' "$ICON_GITHUB" ;;
    *gitlab*)    printf '%s' "$ICON_GITLAB" ;;
    *bitbucket*) printf '%s' "$ICON_BITBUCKET" ;;
    *)           printf '%s' "$ICON_GIT" ;;
  esac
}

# sets globals AHEAD BEHIND WORK STAGE STASH
compute() {
  local ab
  if ab=$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null); then
    BEHIND=${ab%%$'\t'*}; AHEAD=${ab##*$'\t'}
  else BEHIND=0; AHEAD=0; fi
  WORK=0; STAGE=0
  local x y line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    x=${line:0:1}; y=${line:1:1}
    if [ "$x$y" = "??" ]; then WORK=$((WORK+1)); continue; fi
    case "$x" in [MADRC]) STAGE=$((STAGE+1)) ;; esac
    case "$y" in [MD])    WORK=$((WORK+1))   ;; esac
  done < <(git status --porcelain 2>/dev/null)
  STASH=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
}

state() {
  in_repo || return 1
  compute
  if   [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then echo diverged
  elif [ "$AHEAD"  -gt 0 ]; then echo ahead
  elif [ "$BEHIND" -gt 0 ]; then echo behind
  elif [ "$WORK" -gt 0 ] || [ "$STAGE" -gt 0 ]; then echo dirty
  else echo clean; fi
}

render() {
  in_repo || return 0
  compute
  local branch status="" changes=""
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
  if has_upstream; then
    if   [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then status=" ${ICON_AHEAD}${AHEAD} ${ICON_BEHIND}${BEHIND}"
    elif [ "$AHEAD"  -gt 0 ]; then status=" ${ICON_AHEAD}${AHEAD}"
    elif [ "$BEHIND" -gt 0 ]; then status=" ${ICON_BEHIND}${BEHIND}"
    else status=" ${ICON_EQUAL}"; fi
  fi
  [ "$WORK"  -gt 0 ] && changes+="  ${ICON_CHANGED}~${WORK}"
  [ "$STAGE" -gt 0 ] && changes+="  ${ICON_STAGED}~${STAGE}"
  [ "$STASH" -gt 0 ] && changes+="  ${ICON_STASH}${STASH}"
  printf '%s %s %s%s%s' "$(provider_icon)" "$ICON_BRANCH" "$branch" "$status" "$changes"
}

# render() {
#   in_repo || return 0
#   compute
#
#   local branch status="" changes=""
#   branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
#
#   # Upstream tracking status
#   if has_upstream; then
#     if   [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then status="${ICON_AHEAD}${AHEAD} ${ICON_BEHIND}${BEHIND}"
#     elif [ "$AHEAD"  -gt 0 ]; then status="${ICON_AHEAD}${AHEAD}"
#     elif [ "$BEHIND" -gt 0 ]; then status="${ICON_BEHIND}${BEHIND}"
#     else status="${ICON_EQUAL}"; fi
#   fi
#
#   # Local tracking changes
#   [ "$WORK"  -gt 0 ] && changes="${changes:+${changes} }${ICON_CHANGED}~${WORK}"
#   [ "$STAGE" -gt 0 ] && changes="${changes:+${changes} }${ICON_STAGED}~${STAGE}"
#   [ "$STASH" -gt 0 ] && changes="${changes:+${changes} }${ICON_STASH}${STASH}"
#
#   # Assemble the prefix safely
#   local output
#   output="$(provider_icon) $ICON_BRANCH $branch"
#
#   # Append extra segments ONLY if they contain data, adding a single space separator
#   [ -n "$status" ]  && output="$output $status"
#   [ -n "$changes" ] && output="$output $changes"
#
#   # Print the exact string with no trailing whitespace or newlines
#   printf '%s' "$output"
# }

case "$1" in
  state)  state ;;
  render) render ;;
  *) echo "usage: $0 {state|render}" >&2; exit 2 ;;
esac
