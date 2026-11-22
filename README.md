# Claude Code en équipe

Un kit pour qu'une équipe de développeurs utilise Claude Code **de la même façon**,
sans perdre la maîtrise du code ni la sécurité : contexte de projet partagé,
commandes communes du ticket à la merge request, agents spécialisés, garde-fous
automatiques, politique déployable par la DSI et vérification en CI.

> **English summary.** A starter kit to adopt Claude Code as a team, from ticket to
> merge request: a shared `CLAUDE.md` template, slash commands (`/ticket`, `/pr`,
> `/revue-pr`, `/hotfix`, `/incident`, `/adr`…), specialised subagents, hooks
> (secret scanning, quality, destructive command guard, branch guard, audit log),
> a security review skill, enterprise managed settings (MDM), MCP templates (Jira,
> Confluence, GitLab, GitHub, Sentry, SonarQube), Bedrock/Vertex/OTel samples and
> GitHub/GitLab CI. Examples for Symfony, Angular, Java Spring, .NET and FastAPI.
> Docs are in French. MIT licensed.

## Pourquoi

Quand chaque développeur utilise l'IA à sa manière, la revue de code découvre des
fichiers que personne n'a vraiment écrits, et les failles classiques reviennent :
contrôle d'accès fait seulement dans l'interface, secrets dans le code, requêtes
construites à la main. Ce kit versionne les règles dans le dépôt, pour que l'outil
les applique à tout le monde.

## Le workflow

```text
 Ticket (Jira / issue GitLab / issue GitHub)
   │  /cadrage        clarifier, découper
   ▼
 /ticket  ──►  branche  ──►  plan  ──►  tests d'abord  ──►  implémentation
                              │ validation humaine           │ hooks : secrets, qualité,
                              ▼                              ▼ commandes, branche
                           vérification (agent verificateur, tests, lint)
   │
   ▼
 /pr  ──►  PR / MR  ──►  CI (verif, revue-claude)  ──►  /revue-pr + relecteur-securite
                                                          │
                                         revue humaine obligatoire ◄┘
                                                          │
                                                        merge
                                                          │
                          incident ? /incident (Sentry) ─► /hotfix
```

Le détail pas à pas est dans [docs/workflow.md](docs/workflow.md).

## Contenu

| Chemin | Rôle |
|---|---|
| `CLAUDE.md` | Modèle commenté : décrire le projet, ses conventions et ses interdits |
| `.claude/settings.json` | Permissions partagées et branchement des hooks |
| `.claude/commands/` | `/ticket`, `/cadrage`, `/pr`, `/revue-pr`, `/hotfix`, `/incident`, `/adr`, `/onboarding`, `/dette` |
| `.claude/agents/` | Sous-agents : `relecteur-securite`, `testeur`, `architecte`, `verificateur` |
| `.claude/hooks/` | `garde-secrets.sh`, `qualite.sh`, `garde-commandes.sh`, `garde-branche.sh`, `journal.sh` ; tests dans `tests/hooks.bats` |
| `.claude/skills/revue-securite/` | Skill de relecture sécurité du code généré |
| `entreprise/managed-settings.json` | Politique imposée par la DSI (déploiement MDM) |
| `entreprise/mcp.json.exemple` | Serveurs MCP : Jira, Confluence, GitLab, GitHub, Sentry, SonarQube |
| `entreprise/*.env.exemple` | Bedrock, Vertex AI, OpenTelemetry |
| `docs/gouvernance.md` | Gouvernance : données, droits, audit, conformité |
| `.github/workflows/` | CI GitHub : `verif`, `revue-claude`, `release` |
| `.gitlab-ci.yml` | CI GitLab équivalente |
| `.github/` | Templates de PR et de MR |
| `docs/workflow.md`, `docs/adoption.md` | Cycle de dev complet ; déploiement par vagues |
| `exemples/` | `CLAUDE.md` remplis : Symfony, Angular, Java Spring, .NET, FastAPI |

## Installation

### Dans un projet

```bash
# depuis la racine de votre projet
KIT=$(mktemp -d)
git clone --depth 1 https://github.com/Avisers/claude-code-en-equipe "$KIT"
[ -d .claude ] && cp -r .claude .claude.sauvegarde   # si un .claude/ existe déjà
cp -r "$KIT/.claude" .
cp -n "$KIT/CLAUDE.md" .   # ou un fichier de exemples/<stack>/CLAUDE.md
mkdir -p tests && cp -r "$KIT/tests/." tests/
chmod +x .claude/hooks/*.sh
printf '.claude/journal/\n.claude/branche-libre\n.claude/settings.local.json\n' >> .gitignore
```

Puis remplissez `CLAUDE.md` et adaptez les commandes de `qualite.sh` à votre outillage.
Les hooks demandent `bash` et `jq`. Pour tester les hooks : `bats tests/hooks.bats`.

**Hook `qualite.sh` : ce qui tourne par défaut.** Un hook s'exécute hors du bac à sable, avec vos droits.
Par défaut, `qualite.sh` ne lance donc que des outils du `PATH` dont la configuration est déclarative :
`shellcheck`, `gofmt`, `ruff`. Les outils fournis ou pilotés par le dépôt (`vendor/bin/php-cs-fixer`,
`phpstan`, `node_modules/.bin/eslint`, `.venv/bin/ruff`, `mvn`, `./gradlew`, `dotnet format`) ne tournent
qu'avec `export CLAUDE_QUALITE_OUTILS_PROJET=1`. **Risque** : ils exécutent du code du dépôt
(`.php-cs-fixer.php`, `eslint.config.js`, plugins Maven/Gradle, MSBuild) ; une branche ou une dépendance
piégée s'exécute alors hors bac à sable à chaque écriture de Claude. Activez-la seulement sur un dépôt
de confiance, dans votre environnement local, jamais en CI sur des branches tierces.

> **Branches protégées.** `garde-branche.sh` refuse toute écriture de Claude sur
> `main` et `master` : on travaille sur une branche de ticket. La liste se règle
> avec la variable `CLAUDE_BRANCHES_PROTEGEES` (ex. `"main master develop"`).
> Pour lever la garde sur votre poste seulement, c'est à l'humain de lancer
> `touch .claude/branche-libre` (fichier ignoré par git).

### Déploiement par la DSI

Copiez `entreprise/managed-settings.json` à l'emplacement géré de la machine
(macOS : `/Library/Application Support/ClaudeCode/managed-settings.json`,
Linux : `/etc/claude-code/managed-settings.json`) via votre MDM ou outil de gestion
de parc. Cette politique prime sur les réglages utilisateur et projet. Pour
l'accès aux modèles via votre cloud, partez de `entreprise/bedrock.env.exemple` ou
`entreprise/vertex.env.exemple` ; pour la télémétrie, `entreprise/otel.env.exemple`.
Voir [docs/gouvernance.md](docs/gouvernance.md).

## Démarrage en 10 minutes

1. **(2 min)** Copiez `.claude/` et `CLAUDE.md` dans le dépôt, `chmod +x` sur les hooks.
2. **(3 min)** Remplissez `CLAUDE.md` : stack, commandes, sécurité, interdits (partez d'un exemple de `exemples/`).
3. **(1 min)** Branchez Jira ou GitLab : `cp entreprise/mcp.json.exemple .mcp.json`, puis retirez les serveurs inutiles. Les jetons restent en variables d'environnement.
4. **(3 min)** Lancez `claude`, puis `/ticket PROJ-123` sur un petit ticket réel.
5. **(1 min)** Relisez le diff, ouvrez la PR avec `/pr`, laissez un collègue relire.

## Principes

1. **Le contexte est versionné.** `CLAUDE.md` est relu en revue comme du code.
2. **Les garde-fous sont automatiques.** Une règle que l'outil peut contourner n'en est pas une.
3. **Rien n'est fusionné sans relecture humaine.** Le kit aide à relire, il ne relit pas à votre place.
4. **La sécurité se vérifie côté serveur.** Un contrôle dans l'interface n'est pas un contrôle d'accès.
5. **Les tests viennent d'abord.** Une fonctionnalité sans test n'est pas terminée.
6. **Tout est traçable.** Le journal d'audit et la CI permettent de savoir qui a fait quoi.

## Compatibilité

| Besoin | Jira + GitLab | GitHub (issues + PR) |
|---|---|---|
| Source des tickets | MCP Jira / issues GitLab | issues GitHub |
| Ouverture de la revue | merge request | pull request |
| CI | `.gitlab-ci.yml` | `.github/workflows/` |
| Doc / supervision | Confluence, Sentry, SonarQube via MCP | idem |
| Modèles | API Anthropic, Bedrock, Vertex AI | idem |

## Formation

Ce kit est la version publique de ce qu'installe la
[formation Claude Code pour équipes de dev](https://avisers.com/formation-claude-code/)
d'Avisers, sur le code de l'équipe.

## Contribuer et sécurité

Voir [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) et
[CHANGELOG.md](CHANGELOG.md).

## Licence

MIT — voir [LICENSE](LICENSE).
