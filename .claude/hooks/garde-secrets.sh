#!/usr/bin/env bash
# PreToolUse (Read|Write|Edit|MultiEdit|NotebookEdit) : refuse d'écrire un secret et de lire
# les fichiers qui en contiennent (.env*, .envrc, clés privées, credentials, secrets/).
# Noms comparés sans tenir compte de la casse. Les exemples et fixtures ne sont exclus
# QUE de la lecture : tout contenu écrit est scanné, quel que soit le fichier.
# Code de sortie 2 = action bloquée, stderr est renvoyé à Claude.
# Utilise gitleaks s'il est installé, puis les motifs internes ci-dessous.
# GARDE_SECRETS_SANS_GITLEAKS=1 force les seuls motifs internes (tests).
set -euo pipefail
input=$(cat)
outil=$(jq -r '.tool_name // empty' <<<"$input")
fichier=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
shopt -s nocasematch

# Normalise le chemin : retire les « ./ », résout les « .. » et la barre finale, pour que
# tests/fixtures/../../.env ou .env/ ne passent pas pour un fixture ou un dossier.
normaliser() {
  local p=$1 abs="" part out=()
  [[ $p == /* ]] && abs=/
  IFS=/ read -r -a parts <<<"$p"
  for part in ${parts[@]+"${parts[@]}"}; do
    case "$part" in
      ''|.) ;;
      ..) if [ ${#out[@]} -gt 0 ] && [ "${out[${#out[@]}-1]}" != ".." ]; then unset 'out[${#out[@]}-1]'; out=(${out[@]+"${out[@]}"}); elif [ -z "$abs" ]; then out+=(..); fi ;;
      *) out+=("$part") ;;
    esac
  done
  local IFS=/
  printf '%s%s' "$abs" "${out[*]:-}"
}
fichier=$(normaliser "$fichier")
nom=${fichier##*/}

bloquer() { echo "$1" >&2; exit 2; }

# Fichiers d'exemple et fixtures de test : lisibles (contenu factice assumé).
exclu() {
  case "$1" in
    *.exemple|*.example|*.sample|*.dist|*/tests/fixtures/*|tests/fixtures/*|*/__fixtures__/*) return 0 ;;
  esac
  return 1
}

if [ "$outil" = "Read" ]; then
  if exclu "$fichier"; then exit 0; fi
  case "$nom" in
    .env|.env.*|.envrc|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|id_rsa|id_ed25519|id_ecdsa|id_dsa|credentials.json|secrets.*|.npmrc|.pgpass|.netrc|_netrc|.git-credentials)
      bloquer "Lecture refusée : « $nom » contient probablement des secrets. Lisez plutôt le fichier d'exemple (.env.exemple) ou demandez la valeur à un humain." ;;
  esac
  case "$fichier" in
    secrets/*|*/secrets/*)
      bloquer "Lecture refusée : le dossier secrets/ est hors d'atteinte de Claude." ;;
    .aws/credentials|*/.aws/credentials|*/.ssh/*|.docker/config.json|*/.docker/config.json|.env/*|*/.env/*)
      bloquer "Lecture refusée : « $fichier » contient des identifiants." ;;
  esac
  exit 0
fi

contenu=$(jq -r '[.tool_input.content, .tool_input.new_string, .tool_input.new_source, (.tool_input.edits[]?.new_string)] | map(select(. != null)) | join("\n")' <<<"$input")
[ -z "$contenu" ] && exit 0

message="Secret probable détecté dans ${fichier:-le contenu}. Placez-le dans le gestionnaire de secrets du projet (variable d'environnement, coffre) et référencez-le, ne l'écrivez pas dans le code."

if [ -z "${GARDE_SECRETS_SANS_GITLEAKS:-}" ] && command -v gitleaks >/dev/null 2>&1; then
  if ! printf '%s' "$contenu" | gitleaks stdin --no-banner --redact >/dev/null 2>&1; then
    bloquer "$message (détecté par gitleaks)"
  fi
fi

motifs=(
  'AKIA[0-9A-Z]{16}'                                          # AWS access key
  'aws_secret_access_key[[:space:]]*[=:][[:space:]]*["'\'']?[A-Za-z0-9/+=]{40}'  # AWS secret
  'AIza[0-9A-Za-z_-]{35}'                                     # clé API Google
  '"type":[[:space:]]*"service_account"'                      # compte de service GCP
  'AccountKey=[A-Za-z0-9+/=]{40,}'                            # Azure Storage
  'SharedAccessKey=[A-Za-z0-9+/=]{30,}'                       # Azure Service Bus
  'gh[pousr]_[A-Za-z0-9]{36}'                                 # token GitHub
  'github_pat_[A-Za-z0-9_]{60,}'                              # PAT GitHub à grain fin
  'glpat-[A-Za-z0-9_-]{20}'                                   # PAT GitLab
  'xox[baprs]-[A-Za-z0-9-]{10,}'                              # token Slack
  'hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+'  # webhook Slack
  '(sk|rk)_live_[A-Za-z0-9]{20,}'                             # Stripe live
  'sk-(proj|ant)-[A-Za-z0-9_-]{16,}'                          # OpenAI, Anthropic
  'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'  # JWT
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'                        # clé privée
  '[a-z][a-z0-9+.-]*://[^/:@[:space:]]+:[^/@[:space:]]{3,}@[^/[:space:]]+'  # URL de connexion avec mot de passe
  '(Password|Pwd)=[^;[:space:]]{3,}'                          # chaîne de connexion ADO.NET
)
for p in "${motifs[@]}"; do
  if grep -Eq -- "$p" <<<"$contenu"; then
    bloquer "$message (motif : $p)"
  fi
done
# Motifs insensibles à la casse, appliqués même quand gitleaks est présent.
motifs_i=(
  'password[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{6,}'          # mot de passe en dur
)
for p in "${motifs_i[@]}"; do
  if grep -Eiq -- "$p" <<<"$contenu"; then
    bloquer "$message (motif : $p)"
  fi
done
exit 0
