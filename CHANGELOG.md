# Changelog

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versionnement [SemVer](https://semver.org/lang/fr/).

## [2.0.0] - 2026-11-21

### Ajouté

- Commandes : `/cadrage`, `/pr`, `/hotfix`, `/incident`, `/adr`, `/onboarding`, `/dette` (en plus de `/ticket` et `/revue-pr`).
- Sous-agents : `relecteur-securite`, `testeur`, `architecte`, `verificateur`.
- Hooks : `garde-commandes.sh`, `garde-branche.sh`, `journal.sh` ; tests `hooks.bats`.
- Déploiement entreprise : `managed-settings.json`, `mcp.json.exemple`, exemples Bedrock, Vertex AI et OpenTelemetry.
- Documentation : `docs/workflow.md`, `docs/adoption.md`, `docs/gouvernance.md`.
- CI : workflow `release` ; revue IA en local avant push (`/pr`), sans clé en CI, `.gitlab-ci.yml`, templates de PR et de MR.
- Exemples `CLAUDE.md` : Java Spring, .NET, Python FastAPI.
- `CONTRIBUTING.md` et `SECURITY.md`.

### Modifié

- README refait : schéma du workflow, installation projet et DSI, démarrage en 10 minutes.
- `/ticket` couvre Jira et issues GitLab et suit le cycle plan, tests d'abord, vérification, MR.
- Exemples Symfony et Angular complétés (commandes de vérification, interdits).

## [1.0.0] - 2026-10-14

### Ajouté

- Modèle `CLAUDE.md`, hooks `garde-secrets.sh` et `qualite.sh`, commandes `/ticket` et `/revue-pr`.
- Skill `revue-securite`, CI `verif`, exemples Symfony et Angular.
