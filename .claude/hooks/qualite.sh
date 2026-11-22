#!/usr/bin/env bash
# PostToolUse : lance le linter ou le formateur adapté au fichier modifié.
# Les erreurs sont renvoyées à Claude (code 2) pour qu'il corrige aussitôt.
# Outil absent ou non configuré : on ne fait rien (code 0). Adaptez à votre outillage.
set -uo pipefail
file=$(jq -r '.tool_input.file_path // empty')
if [ -z "$file" ] || [ ! -f "$file" ]; then exit 0; fi
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

a() { command -v "$1" >/dev/null 2>&1; }
cmd=()
case "$file" in
  *.php)
    if [ -x vendor/bin/php-cs-fixer ]; then cmd=(vendor/bin/php-cs-fixer fix --dry-run --diff "$file")
    elif [ -x vendor/bin/phpstan ]; then cmd=(vendor/bin/phpstan analyse --no-progress --error-format=raw "$file"); fi ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs)
    if [ -x node_modules/.bin/eslint ]; then cmd=(node_modules/.bin/eslint "$file"); fi ;;
  *.py)
    if a ruff; then cmd=(ruff check "$file")
    elif [ -x .venv/bin/ruff ]; then cmd=(.venv/bin/ruff check "$file"); fi ;;
  *.go)
    if a gofmt; then
      out=$(gofmt -l "$file" 2>&1)
      if [ -n "$out" ]; then echo "gofmt : fichier non formaté ($out). Lancez gofmt -w $file." >&2; exit 2; fi
    fi
    exit 0 ;;
  *.java)
    if [ -f pom.xml ] && a mvn; then
      if grep -q spotless pom.xml; then cmd=(mvn -q spotless:check)
      elif grep -q maven-checkstyle-plugin pom.xml; then cmd=(mvn -q checkstyle:check); fi
    fi ;;
  *.cs)
    if a dotnet; then cmd=(dotnet format --verify-no-changes --include "$file"); fi ;;
  *.sh)
    if a shellcheck; then cmd=(shellcheck "$file"); fi ;;
esac
[ ${#cmd[@]} -eq 0 ] && exit 0

if ! out=$("${cmd[@]}" 2>&1); then
  echo "$out" >&2
  exit 2
fi
exit 0
