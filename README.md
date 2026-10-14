# Claude Code en équipe

Un kit pour qu'une équipe de développeurs utilise Claude Code **de la même façon**,
sans perdre la maîtrise du code ni la sécurité : contexte de projet partagé,
garde-fous automatiques, commandes communes, vérification en CI.

> **English summary.** A starter kit to adopt Claude Code as a team: a shared
> `CLAUDE.md` template, quality and secret-scanning hooks, shared slash commands,
> a security review skill and a CI workflow, with Symfony and Angular examples.
> Docs are in French. MIT licensed.

## Pourquoi

Quand chaque développeur utilise l'IA à sa manière, la revue de code découvre des
fichiers que personne n'a vraiment écrits, et les failles classiques reviennent :
contrôle d'accès fait seulement dans l'interface, secrets dans le code, requêtes
construites à la main. Ce kit versionne les règles dans le dépôt, pour que l'outil
les applique à tout le monde.

## Contenu

| Chemin | Rôle |
|---|---|
| `CLAUDE.md` | Modèle commenté : décrire le projet, ses conventions et ses interdits |
| `.claude/settings.json` | Permissions partagées et branchement des hooks |
| `.claude/hooks/garde-secrets.sh` | Bloque l'écriture d'un fichier qui contient un secret probable |
| `.claude/hooks/qualite.sh` | Lance le linter adapté au fichier modifié |
| `.claude/commands/` | Commandes partagées : `/revue-pr`, `/ticket` |
| `.claude/skills/revue-securite/` | Skill de relecture sécurité du code généré |
| `.github/workflows/verif.yml` | CI : recherche de secrets et lint des scripts du kit |
| `exemples/symfony/`, `exemples/angular/` | `CLAUDE.md` remplis pour ces deux stacks |

## Installation

```bash
# depuis la racine de votre projet
git clone --depth 1 https://github.com/Avisers/claude-code-en-equipe /tmp/kit
cp -r /tmp/kit/.claude .
cp /tmp/kit/CLAUDE.md .            # ou exemples/symfony/CLAUDE.md, exemples/angular/CLAUDE.md
chmod +x .claude/hooks/*.sh
```

Puis remplissez `CLAUDE.md` et adaptez les commandes de `qualite.sh` à votre outillage.
Les hooks demandent `bash` et `jq`.

## Principes

1. **Le contexte est versionné.** `CLAUDE.md` est relu en revue comme du code.
2. **Les garde-fous sont automatiques.** Une règle que l'outil peut contourner n'en est pas une.
3. **Rien n'est fusionné sans relecture humaine.** Le kit aide à relire, il ne relit pas à votre place.
4. **La sécurité se vérifie côté serveur.** Un contrôle dans l'interface n'est pas un contrôle d'accès.

## Formation

Ce kit est la version publique de ce qu'installe la
[formation Claude Code pour équipes de dev](https://avisers.com/formation-claude-code/)
d'Avisers, sur le code de l'équipe.

## Licence

MIT — voir [LICENSE](LICENSE). Contributions bienvenues par issue ou pull request.
