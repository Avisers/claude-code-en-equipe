#!/usr/bin/env bash
# PreToolUse : refuse d'écrire un contenu qui ressemble à un secret.
# Code de sortie 2 = action bloquée, le message est renvoyé à Claude.
set -euo pipefail
input=$(cat)
content=$(jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits[]?.new_string)] | map(select(. != null)) | join("\n")' <<<"$input")

patterns=(
  'AKIA[0-9A-Z]{16}'                                  # clé AWS
  'sk-(live|proj|ant)-[A-Za-z0-9_-]{16,}'             # Stripe live, OpenAI, Anthropic
  'ghp_[A-Za-z0-9]{36}'                               # token GitHub
  'xox[baprs]-[A-Za-z0-9-]{10,}'                      # token Slack
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'                # clé privée
  'service_role[^\n]{0,40}eyJ[A-Za-z0-9_-]{20,}'      # clé service_role Supabase
)
for p in "${patterns[@]}"; do
  if grep -Eq -- "$p" <<<"$content"; then
    echo "Secret probable détecté (motif : $p). Placez-le dans le gestionnaire de secrets du projet, pas dans le code." >&2
    exit 2
  fi
done
exit 0
