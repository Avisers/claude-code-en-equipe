#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit) : refuse de modifier des fichiers sur une branche protégée.
# Branches protégées : CLAUDE_BRANCHES_PROTEGEES (séparées par des espaces), « main master » par défaut.
# Levée locale : créer le fichier .claude/branche-libre (à ne pas versionner).
set -euo pipefail
input=$(cat)
projet=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<<"$input")}
[ -n "$projet" ] || exit 0
[ -e "$projet/.claude/branche-libre" ] && exit 0
branche=$(git -C "$projet" branch --show-current 2>/dev/null || true)
[ -n "$branche" ] || exit 0
for b in ${CLAUDE_BRANCHES_PROTEGEES:-main master}; do
  if [ "$branche" = "$b" ]; then
    echo "Modification refusée : la branche courante « $branche » est protégée. Créez une branche de travail (git switch -c feat/…), ou créez .claude/branche-libre pour lever la garde localement." >&2
    exit 2
  fi
done
exit 0
