#!/usr/bin/env bash
# PostToolUse : journal d'audit JSONL dans .claude/journal/AAAA-MM-JJ.jsonl.
# Consigne l'heure, l'outil et sa cible (fichier, ou commande tronquée et masquée), jamais le contenu.
# Ne bloque jamais : toute erreur est ignorée.
set -uo pipefail
input=$(cat)
projet=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)}
[ -n "$projet" ] || exit 0
dossier="$projet/.claude/journal"
mkdir -p "$dossier" 2>/dev/null || exit 0
cible=$(jq -r '.tool_input.file_path // .tool_input.path // .tool_input.command // .tool_input.url // .tool_input.pattern // empty' <<<"$input" 2>/dev/null | head -n1 | cut -c1-200)
# Masque : NOM_CONTENANT_PASS|PWD|TOKEN|SECRET|KEY=valeur (casse ignorée, guillemet fermant
# conservé), -u/--user user:mdp de curl, -p<mdp> de mysql,
# Authorization: Bearer/Basic, mots de passe d'URL (://user:pass@) et jetons longs.
# Casse ignorée sans sed -I (absent sur macOS) : chaque lettre devient [Xx].
ci() { local i c r=""; for ((i = 0; i < ${#1}; i++)); do c=${1:i:1}; r+="[$(tr '[:lower:]' '[:upper:]' <<<"$c")$c]"; done; printf '%s' "$r"; }
mots="($(ci pass)|$(ci pwd)|$(ci token)|$(ci secret)|$(ci key))"
cible=$(sed -E \
  -e "s/([A-Za-z_-]*${mots}[A-Za-z_-]*[[:space:]]*[=:][[:space:]]*)[^'\"[:space:]&]+/\1***/g" \
  -e "s/((^|[[:space:]])(-u|--user)[[:space:]=]*[^:'\"[:space:]]+:)[^'\"[:space:]]+/\1***/g" \
  -e "/$(ci mysql)|$(ci mariadb)/s/(^|[[:space:]])-p[^[:space:]]+/\1-p***/g" \
  -e "s/($(ci authorization):[[:space:]]*([A-Za-z]+[[:space:]]+)?)[^'\"[:space:]]+/\1***/g" \
  -e "s/($(ci bearer)[[:space:]]+)[^'\"[:space:]]+/\1***/g" \
  -e 's#(://[^/:@[:space:]]+:)[^@[:space:]]+@#\1***@#g' \
  -e 's/[A-Za-z0-9_+=-]{32,}/***/g' <<<"$cible")
jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg session "$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)" \
  --arg outil "$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null)" \
  --arg cible "$cible" \
  '{ts:$ts, session:$session, outil:$outil, cible:$cible}' >>"$dossier/$(date -u +%F).jsonl" 2>/dev/null
exit 0
