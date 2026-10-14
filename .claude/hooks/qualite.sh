#!/usr/bin/env bash
# PostToolUse : lance le linter adapté au fichier modifié.
# Les erreurs sont renvoyées à Claude (code 2) pour qu'il corrige aussitôt.
# Adaptez les commandes à votre outillage.
set -uo pipefail
file=$(jq -r '.tool_input.file_path // empty')
if [ -z "$file" ] || [ ! -f "$file" ]; then exit 0; fi
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

cmd=()
case "$file" in
  *.php) [ -x vendor/bin/phpstan ] && cmd=(vendor/bin/phpstan analyse --no-progress --error-format=raw "$file") ;;
  *.ts|*.js) [ -x node_modules/.bin/eslint ] && cmd=(node_modules/.bin/eslint "$file") ;;
  *.sh) command -v shellcheck >/dev/null && cmd=(shellcheck "$file") ;;
esac
[ ${#cmd[@]} -eq 0 ] && exit 0

if ! out=$("${cmd[@]}" 2>&1); then
  echo "$out" >&2
  exit 2
fi
exit 0
