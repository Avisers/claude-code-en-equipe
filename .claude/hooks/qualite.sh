#!/usr/bin/env bash
# PostToolUse : lance le linter ou le formateur adapté au fichier modifié.
# Les erreurs sont renvoyées à Claude (code 2) pour qu'il corrige aussitôt.
# Outil absent ou non configuré : on ne fait rien (code 0). Adaptez à votre outillage.
#
# Un hook tourne HORS du bac à sable, avec tous les droits de l'utilisateur. Par défaut on
# n'exécute donc que des outils du PATH qui n'exécutent pas de code fourni par le dépôt :
# ShellCheck, gofmt, ruff (leur configuration est déclarative).
#
# CLAUDE_QUALITE_OUTILS_PROJET=1 active en plus les outils fournis ou pilotés par l'espace de
# travail : vendor/bin (php-cs-fixer, phpstan), node_modules/.bin (eslint), .venv/bin, mvn,
# gradle, dotnet. RISQUE : ces outils exécutent du code du dépôt (binaires installés,
# .php-cs-fixer.php, eslint.config.js, plugins Maven/Gradle, MSBuild). Une branche ou une
# dépendance piégée exécute alors du code hors bac à sable à chaque écriture de Claude.
# N'activez cette variable que sur des dépôts de confiance, dans votre environnement local.
set -uo pipefail
file=$(jq -r '.tool_input.file_path // empty')
if [ -z "$file" ] || [ ! -f "$file" ]; then exit 0; fi
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

a() { command -v "$1" >/dev/null 2>&1; }
projet() { [ "${CLAUDE_QUALITE_OUTILS_PROJET:-}" = "1" ]; }
cmd=()
case "$file" in
  *.php)
    if projet && [ -x vendor/bin/php-cs-fixer ]; then cmd=(vendor/bin/php-cs-fixer fix --dry-run --diff "$file")
    elif projet && [ -x vendor/bin/phpstan ]; then cmd=(vendor/bin/phpstan analyse --no-progress --error-format=raw "$file"); fi ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs)
    if projet && [ -x node_modules/.bin/eslint ]; then cmd=(node_modules/.bin/eslint "$file"); fi ;;
  *.py)
    if a ruff; then cmd=(ruff check "$file")
    elif projet && [ -x .venv/bin/ruff ]; then cmd=(.venv/bin/ruff check "$file"); fi ;;
  *.go)
    if a gofmt; then
      out=$(gofmt -l "$file" 2>&1)
      if [ -n "$out" ]; then echo "gofmt : fichier non formaté ($out). Lancez gofmt -w $file." >&2; exit 2; fi
    fi
    exit 0 ;;
  *.java)
    if projet && [ -f pom.xml ] && a mvn; then
      if grep -q spotless pom.xml; then cmd=(mvn -q spotless:check)
      elif grep -q maven-checkstyle-plugin pom.xml; then cmd=(mvn -q checkstyle:check); fi
    elif projet && [ -x ./gradlew ] && grep -qs spotless build.gradle build.gradle.kts; then
      cmd=(./gradlew -q spotlessCheck)
    fi ;;
  *.cs)
    if projet && a dotnet; then cmd=(dotnet format --verify-no-changes --include "$file"); fi ;;
  *.sh)
    if a shellcheck; then cmd=(shellcheck "$file"); fi ;;
esac
[ ${#cmd[@]} -eq 0 ] && exit 0

if ! out=$("${cmd[@]}" 2>&1); then
  echo "$out" >&2
  exit 2
fi
exit 0
