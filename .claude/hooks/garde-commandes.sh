#!/usr/bin/env bash
# PreToolUse (Bash) : bloque les commandes destructrices ou dangereuses.
# Code de sortie 2 = commande bloquée, stderr est renvoyé à Claude.
# Compatible bash 3.2 (macOS). Analyse lexicale volontairement simple : c'est une
# ceinture de sécurité, pas un coffre-fort (voir docs/gouvernance.md, « Limites des hooks »).
set -euo pipefail
input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -z "$cmd" ] && exit 0
projet=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<<"$input")}
shopt -s nocasematch

bloquer() { echo "Commande bloquée : $1" >&2; exit 2; }
a() { grep -Eiq -- "$1" <<<"$cmd"; }

# ---------- Découpage en segments ----------
# Séparateurs : ; && || | & ( ) { } ` $( et retours à la ligne. Les guillemets sont
# ignorés pour le découpage, ce qui ouvre aussi le contenu de bash -c "…".
s=$cmd
# shellcheck disable=SC2016 # « $( » est un séparateur littéral.
for sep in '&&' '||' ';' '|' '&' '(' ')' '{' '}' '`' '$('; do
  s=${s//"$sep"/$'\n'}
done

# Retire guillemets et antislash initial d'un mot (« \rm », "rm", '$HOME').
deq() { local m=${1//\"/}; m=${m//\'/}; printf '%s' "${m#\\}"; }

# Vrai si la cible d'une suppression est dangereuse : variable, ~, .., absolu hors projet.
cible_dangereuse() {
  case "$1" in
    *'$'*|*'`'*|'~'*|..|../*|*/..|*/../*|'*'|'/*') return 0 ;;
    /*) [ -n "$projet" ] && [[ $1 == "$projet"/* ]] && return 1; return 0 ;;
  esac
  return 1
}

# Vrai si le chemin désigne un fichier de secrets (casse ignorée, exemples exclus).
sensible() {
  local p=$1 n
  while [[ $p == */ ]]; do p=${p%/}; done
  n=${p##*/}
  case "$n" in
    *.exemple|*.example|*.sample|*.dist|*.template|*.pub) return 1 ;;
    .env|.env.*|.envrc|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|id_rsa|id_ed25519|id_ecdsa|id_dsa|credentials.json|secrets.*|.npmrc|.pgpass|.netrc|_netrc|.git-credentials) return 0 ;;
  esac
  case "$p" in
    secrets/*|*/secrets/*|.aws/credentials|*/.aws/credentials|*/.ssh/*|.docker/config.json|*/.docker/config.json|.env/*|*/.env/*) return 0 ;;
  esac
  return 1
}

# Vrai si les mots contiennent à la fois une option récursive et une option forcée.
rf_options() {
  local m r=0 f=0
  for m in "$@"; do
    case "$m" in
      --recursive) r=1 ;;
      --force) f=1 ;;
      --*) ;;
      -*) [[ $m == *r* ]] && r=1; [[ $m == *f* ]] && f=1 ;;
    esac
  done
  [ $r -eq 1 ] && [ $f -eq 1 ]
}

# Vrai si une cible de cd ou de rm est simple : relative, sans .., $, ~ ni / en tête.
simple() {
  case "$1" in
    ''|'/'*|'~'*|*'$'*|*'`'*|..|../*|*/..|*/../*|'*') return 1 ;;
  esac
  return 0
}

protegee() {
  case "$1" in
    main|master|develop|release*|head|@) return 0 ;;
  esac
  return 1
}

# Normalise chaque segment : mots dé-guillemetés, préfixes (env, command, exec, sudo,
# nice, nohup, time, doas, VAR=val) et enveloppes sh -c / bash -c retirés.
segs=()
while IFS= read -r seg; do
  read -r -a brut <<<"$seg" || true
  mots=()
  for m in ${brut[@]+"${brut[@]}"}; do mots+=("$(deq "$m")"); done
  tete=1
  while [ -n "${mots[0]:-}" ]; do
    premier=${mots[0]}
    # Mot de tête dynamique ($x, $(…), `…`, eval, ou option orpheline laissée par
    # « $(echo rm) -rf ») suivi d'options récursives et forcées : refus.
    case "$tete$premier" in
      *'$'*|*'`'*|*eval|1-*)
        rf_options "${mots[@]}" && bloquer "commande dynamique (\$x, \$(…), eval) avec options récursives et forcées. Écrivez la commande en clair." ;;
    esac
    tete=0
    case "$premier" in -*|*=*) mots=("${mots[@]:1}"); continue ;; esac
    premier=${premier##*/}
    case "$premier" in
      env|command|exec|sudo|doas|nice|nohup|time|builtin|eval) mots=("${mots[@]:1}") ;;
      xargs)
        # xargs exécute la suite : on saute ses options (et leur valeur) puis on analyse la commande.
        mots=("${mots[@]:1}")
        while [[ ${mots[0]:-} == -* ]]; do
          case "${mots[0]}" in
            -I|-n|-P|-L|-d|-s|-E|-a) mots=("${mots[@]:2}") ;;
            *) mots=("${mots[@]:1}") ;;
          esac
        done
        # Les cibles viennent de stdin : impossibles à vérifier ici.
        if [ "${mots[0]##*/}" = rm ] && rf_options "${mots[@]}"; then
          bloquer "xargs rm -rf : les cibles viennent de stdin et ne peuvent pas être vérifiées. Listez les chemins explicitement."
        fi ;;
      sh|bash|zsh|dash|ksh)
        if [ ${#mots[@]} -gt 1 ] && [[ ${mots[1]} == -*c* ]]; then mots=("${mots[@]:2}"); else break; fi ;;
      *) break ;;
    esac
  done
  # bash 3.2 : "${t[@]:1}" d'un tableau à un élément peut laisser un élément vide.
  [ -z "${mots[0]:-}" ] && continue
  mots[0]=${mots[0]##*/}
  segs+=("${mots[*]}")
done <<<"$s"
[ ${#segs[@]} -eq 0 ] && exit 0

# Premier passage : contexte de la commande entière.
avec_cd=0; telechargement=0; interpreteur=0
for seg in "${segs[@]}"; do
  read -r -a w <<<"$seg"
  c=${w[0]:-}
  case "$c" in
    # cd vers une cible simple (cd app) ne rend pas rm -rf ambigu ; cd /, cd ~, cd .., cd seul, si.
    cd|pushd) simple "${w[1]:-}" || avec_cd=1 ;;
    curl|wget|aria2c|fetch) telechargement=1 ;;
    source|.|./*) interpreteur=1 ;;
    sh|bash|zsh|dash|ksh|fish|python*|perl|ruby|node|nodejs|php|deno|bun|pwsh)
      # Bloqué s'il exécute stdin ou un fichier ; -c/-e (code en ligne) et -m (module) passent.
      code_en_ligne=0
      for m in "${w[@]:1}"; do
        case "$m" in -c|-e|-E|-m|-r|--eval|--version|-V) code_en_ligne=1 ;; esac
      done
      [ $code_en_ligne -eq 0 ] && interpreteur=1 ;;
  esac
done
if [ $telechargement -eq 1 ] && [ $interpreteur -eq 1 ]; then
  bloquer "téléchargement exécuté dans la même commande (curl | sh, curl -o f; sh f, | python…). Téléchargez, relisez, vérifiez la somme de contrôle, puis exécutez séparément."
fi

# Texte tel que bash le verra après retrait des guillemets et des antislashs :
# « .e"n"v », « .e\nv » et « '.env' » redeviennent « .env ».
nu=$(tr -d "\\\\\"'" <<<"$cmd")

# Vrai si un mot contenant un joker (? * [) peut s'étendre en un nom sensible.
# Comme bash sans dotglob, un joker en tête ne capture pas un nom commençant par un point ;
# un joker d'extension pur (*.json) ne vise que les clés (*.pem, *.key…).
candidats_point=(.env .env.local .env.prod .envrc .npmrc .pgpass .netrc .git-credentials)
candidats=(id_rsa id_ed25519 id_ecdsa server.pem server.key cert.p12 cert.pfx credentials.json secrets.yaml secrets.json)
joker_sensible() {
  local b=${1%/} c
  b=${b##*/}
  case "$b" in *[?*[]*) ;; *) return 1 ;; esac
  for c in "${candidats_point[@]}"; do
    # shellcheck disable=SC2053 # $b est volontairement un motif.
    [[ $b == .* ]] && [[ $c == $b ]] && return 0
  done
  case "$b" in '*'|'**') return 1 ;; esac
  for c in "${candidats[@]}"; do
    case "$b" in '*.'*) case "$c" in *.pem|*.key|*.p12|*.pfx) ;; *) continue ;; esac ;; esac
    # shellcheck disable=SC2053
    [[ $c == $b ]] && return 0
  done
  return 1
}

# La levée de garde-branche appartient à l'humain (nom littéral ou joker qui s'y étend).
libre=0
grep -Eiq 'branche-libre' <<<"$nu" && libre=1
if [ $libre -eq 0 ]; then
  while read -r t; do
    case "$t" in *[?*[]*) ;; *) continue ;; esac
    b=${t##*/}
    # shellcheck disable=SC2053
    [[ branche-libre == $b ]] && [ "$b" != '*' ] && libre=1
  done < <(tr " \t=:(),;|&<>{}\`" '\n' <<<"$nu")
fi
if [ $libre -eq 1 ]; then
  if grep -Eiq '>|(^|[^a-z])(touch|cp|mv|tee|ln|install|rsync|dd|mkdir|truncate|sed|python[0-9.]*|perl|ruby|node)([^a-z]|$)' <<<"$nu"; then
    bloquer "écriture de .claude/branche-libre. Seul un humain lève la garde de branche."
  fi
fi

# Mention d'un fichier de secrets n'importe où dans la commande (cat .env, < .env, dd if=.env,
# git show HEAD:.env, python3 -c "open('.env')", cat .e*v…), sur le texte dé-guillemeté,
# découpé sur les blancs, = : ( ) , ; | & < et accolades. Seule la cible d'une redirection
# de sortie (> .env) est tolérée : écrire n'expose pas le contenu existant.
# Exception étroite : « cp [-n] / install » d'un modèle (*.example, *.exemple, *.sample, *.dist)
# VERS .env ou .env.* — l'initialisation classique. La suite de la commande reste analysée.
# ls ne lit que des noms : ses jokers (ls .e*, ls -d .[a-z]*) sont tolérés.
seul_ls=1
for seg in "${segs[@]}"; do [ "${seg%% *}" = ls ] || seul_ls=0; done
# Pas d'exemption si la commande contient une expansion ou une substitution.
grep -Eq '[$`]|<\(|>\(' <<<"$cmd" && seul_ls=0

# Expansions qui fabriquent un nom à l'exécution ($'…', {a,b}, ${…}) dans un mot qui commence
# comme un fichier caché sensible (.e → .env, .n → .npmrc/.netrc, .p → .pgpass, .g → .git-credentials,
# .d → .docker, .a → .aws, .s → .ssh) : refus, le nom réel est invisible ici.
if [ $seul_ls -eq 0 ] && grep -Eq "(^|[[:space:]/=:<'\"])(\.([enpgdas]|\\$|\\{)[^[:space:]]*(\\$'|\\{[^}[:space:]]*,|\\$\\{)|\\$'\\\\?\.?[enpgdas\\\\])" <<<"$cmd"; then
  bloquer "nom de fichier caché construit par expansion (\$'…', {a,b} ou \${…}) : il peut désigner un fichier de secrets. Écrivez le nom en clair."
fi

modele='(^|[;&|[:space:]])(cp|install)([[:space:]]+-n)?[[:space:]]+[^[:space:];&|]+\.(example|exemple|sample|dist)[[:space:]]+([^[:space:];&|]*/)?\.env(\.[A-Za-z0-9_-]+)?([[:space:]]*($|[;&|]))'
while read -r t; do
  [ -z "$t" ] && continue
  sensible "$t" && bloquer "accès à « $t » : fichier de secrets. Lisez le fichier d'exemple (.env.example) ou demandez la valeur à un humain."
  [ $seul_ls -eq 0 ] && joker_sensible "$t" && bloquer "joker « $t » qui peut désigner un fichier de secrets. Nommez le fichier voulu explicitement."
done < <(sed -E -e "s#$modele#\1\7#g" -e 's/>>?[[:space:]]*[^[:space:]]+//g' <<<"$nu" | tr " \t=:(),;|&<{}\`" '\n' || true)

# Second passage : analyse segment par segment.
for seg in "${segs[@]}"; do
  read -r -a w <<<"$seg"
  c=${w[0]:-}
  [ -z "$c" ] && continue
  args=("${w[@]:1}")
  case "$c" in
    rm)
      r=0; f=0; cibles=()
      for m in ${args[@]+"${args[@]}"}; do
        case "$m" in
          --recursive) r=1 ;;
          --force) f=1 ;;
          --*) ;;
          -*) [[ $m == *r* ]] && r=1; [[ $m == *f* ]] && f=1 ;;
          *) cibles+=("$m") ;;
        esac
      done
      { [ $r -eq 1 ] && [ $f -eq 1 ]; } || continue
      [ $avec_cd -eq 1 ] && bloquer "rm -rf combiné à cd : la cible réelle dépend du répertoire courant. Lancez rm -rf seul, avec un chemin relatif au projet."
      for t in ${cibles[@]+"${cibles[@]}"}; do
        case "$t" in
          /|/\*|\~*|\$HOME*|\$\{HOME\}*|..|../*|*/../*|*/..)
            bloquer "rm -rf sur « $t » (racine, home ou dossier parent). Supprimez des chemins précis à l'intérieur du projet." ;;
        esac
        cible_dangereuse "$t" && bloquer "rm -rf sur « $t », variable ou chemin hors du projet. Ne supprimez que dans le dépôt, avec un chemin relatif explicite."
      done ;;
    find)
      if [[ " ${args[*]:-} " == *" -delete "* ]] || [[ " ${args[*]:-} " =~ \ -exec(dir)?\ (rm|shred|unlink)\  ]]; then
        for t in ${args[@]+"${args[@]}"}; do
          case "$t" in -*|'('|'!') break ;; esac
          cible_dangereuse "$t" && bloquer "find … -delete sur « $t », hors du projet. Limitez la recherche à un dossier du dépôt."
        done
      fi ;;
    chmod)
      for m in ${args[@]+"${args[@]}"}; do
        case "$m" in
          -*) ;;
          0[0-7][0-7][2367]|[0-7][0-7][2367]|[0-7][0-7][0-7][2367]|a+*w*|o+*w*|+*w*|a=*w*|o=*w*|ugo+*w*|*,o+*w*|*,a+*w*)
            bloquer "chmod « $m » rend le fichier modifiable par tous. Donnez les droits minimaux (ex. 755 ou 644)." ;;
        esac
      done ;;
    rg)
      for m in ${args[@]+"${args[@]}"}; do
        case "$m" in --pre|--pre=*) bloquer "rg --pre exécute un programme arbitraire sur chaque fichier." ;; esac
      done ;;
    git)
      i=0; n=${#args[@]}
      while [ "$i" -lt "$n" ]; do
        m=${args[$i]}
        case "$m" in
          -c)
            v=${args[$((i+1))]:-}
            case "$v" in
              *pager*|*sshcommand*|*external*|*fsmonitor*|*hookspath*|*editor*|*textconv*|alias.*|*gitproxy*|*credential.helper*|*askpass*|protocol.*)
                bloquer "git -c « $v » peut exécuter un programme arbitraire." ;;
            esac
            i=$((i+2)) ;;
          -C|--git-dir|--work-tree|--namespace) i=$((i+2)) ;;
          -*) i=$((i+1)) ;;
          *) break ;;
        esac
      done
      sous=${args[$i]:-}
      reste=("${args[@]:$((i+1))}")
      for m in ${reste[@]+"${reste[@]}"}; do
        case "$m" in
          --ext-diff|--output|--output=*|--upload-pack*|--receive-pack*|--exec=*)
            bloquer "option git « $m » : exécution ou écriture de fichier arbitraire." ;;
        esac
      done
      case "$sous" in
        clean)
          drapeaux=""
          for m in ${reste[@]+"${reste[@]}"}; do
            case "$m" in --force) drapeaux+="f" ;; --*) ;; -*) drapeaux+="${m#-}" ;; esac
          done
          if [[ $drapeaux == *f* ]] && [[ $drapeaux == *[dxX]* ]]; then
            bloquer "git clean -fd/-fx supprime les fichiers non suivis (travail non commité, .env…). Utilisez git clean -n pour lister, puis supprimez des chemins précis."
          fi ;;
        push)
          force=0; supp=0; tout=0; pos=()
          j=0; nr=${#reste[@]}
          while [ "$j" -lt "$nr" ]; do
            m=${reste[$j]}
            case "$m" in
              --force|--force-with-lease*|--force-if-includes) force=1 ;;
              --delete) supp=1 ;;
              --mirror|--all|--branches) tout=1 ;;
              --push-option|--repo|--receive-pack) j=$((j+1)) ;;
              --*) ;;
              -o) j=$((j+1)) ;;
              -*) [[ $m == *f* ]] && force=1; [[ $m == *d* ]] && supp=1 ;;
              *) pos+=("$m") ;;
            esac
            j=$((j+1))
          done
          refs=(); k=0
          for m in ${pos[@]+"${pos[@]}"}; do
            k=$((k+1)); [ $k -gt 1 ] && [ -n "$m" ] && refs+=("$m")
          done
          if [ $tout -eq 1 ] && { [ $force -eq 1 ] || [[ " ${reste[*]} " == *" --mirror "* ]]; }; then
            bloquer "git push --mirror/--all forcé : réécrit toutes les branches, partagées comprises."
          fi
          if [ $force -eq 1 ] && [ ${#refs[@]} -eq 0 ]; then
            bloquer "git push forcé sans refspec : la branche visée n'est pas explicite. Nommez une branche de travail (git push -f origin feat/x)."
          fi
          for ref in ${refs[@]+"${refs[@]}"}; do
            plus=0; deux=0
            [[ $ref == +* ]] && plus=1 && ref=${ref#+}
            [[ $ref == :* ]] && deux=1
            dst=${ref##*:}
            dst=${dst#refs/heads/}
            dst=${dst%%[~^@]*}
            [ -z "$dst" ] && dst=${ref##*:}
            if protegee "$dst" && { [ $force -eq 1 ] || [ $plus -eq 1 ] || [ $supp -eq 1 ] || [ $deux -eq 1 ]; }; then
              bloquer "push forcé ou suppression de la branche partagée « $dst » (main/master/develop/release). Poussez sur une branche de travail et ouvrez une PR."
            fi
          done ;;
      esac ;;
  esac
done

if a 'git[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-][^[:space:]]*[[:space:]]+)?)*reset[[:space:]].*--hard'; then
  bloquer "git reset --hard détruit le travail non commité. Utilisez git stash ou git restore sur des fichiers précis."
fi
if a '(^|[[:space:]])--no-verify([[:space:]]|$)'; then
  bloquer "--no-verify contourne les hooks. Corrigez ce que signalent les hooks au lieu de les sauter."
fi
if a '(drop[[:space:]]+(database|schema)|truncate[[:space:]]+(table[[:space:]]+)?[A-Za-z_"`]|doctrine:database:drop|db:drop|migrate:fresh)'; then
  bloquer "suppression ou vidage de base de données. Demandez une autorisation explicite à un humain."
fi
if a 'terraform[[:space:]]+(destroy|apply[[:space:]].*-destroy)'; then
  bloquer "terraform destroy. L'infrastructure se détruit par un humain, après revue du plan."
fi
if a 'kubectl[[:space:]].*delete' && a '(prod|production)'; then
  bloquer "kubectl delete sur un contexte ou namespace de production. Passez par le pipeline de déploiement."
fi
exit 0
