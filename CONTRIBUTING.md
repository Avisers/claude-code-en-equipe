# Contribuer

Merci de votre intérêt. Les contributions passent par issue ou pull request.

## Avant de commencer

- Ouvrez une issue pour tout changement non trivial (nouvelle commande, nouveau hook, nouvelle stack).
- Une PR traite un seul sujet.

## Conventions

- Documentation en français, accents corrects ; identifiants de code, noms de fichiers et commandes en VO.
- Scripts : `bash` strict (`set -euo pipefail`), vérifiés par `shellcheck`.
- Hooks : toute modification arrive avec un test dans `tests/hooks.bats`.
- Exemples de stack : même structure que `exemples/symfony/CLAUDE.md` (Projet, Conventions, Sécurité, Ne pas faire sans demander), commandes réelles et sécurité propre à la stack.
- Markdown : `npx -y markdownlint-cli2 "**/*.md"` doit passer.

## Vérifications locales

```bash
shellcheck .claude/hooks/*.sh
bats tests/hooks.bats          # si bats est installé
npx -y markdownlint-cli2 "**/*.md"
```

## Pull request

1. Décrivez le problème résolu et la façon de le vérifier.
2. Mettez à jour `CHANGELOG.md` (section « Non publié »).
3. Aucun secret, aucun nom de client ou de projet privé.
4. Un mainteneur relit ; la CI doit être verte.

## Licence

En contribuant, vous acceptez que votre contribution soit publiée sous licence MIT.
Pour une faille de sécurité, ne passez pas par une issue publique : voir [SECURITY.md](SECURITY.md).
