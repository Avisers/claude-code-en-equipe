---
description: Corriger en urgence un bug de production — branche depuis la prod, correctif minimal, test de non-régression, double revue, backport
argument-hint: <PROJ-123 ou description du bug> [tag ou branche de prod]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git tag:*), Bash(git fetch:*), Bash(git describe:*), Bash(git switch:*), Bash(git checkout -b:*), mcp__atlassian__*, mcp__sentry__*
---
Bug : $ARGUMENTS

Un hotfix est le **plus petit changement sûr** qui rétablit le service. Le reste
(refactoring, amélioration) part dans un ticket séparé.

## 1. Situer la production
- Identifie ce qui tourne en prod : dernier tag (`git describe --tags --abbrev=0`)
  ou branche de prod du projet (`CLAUDE.md`). Demande si c'est ambigu.
- Lis le ticket (MCP `atlassian`) ou l'issue Sentry (MCP `sentry`) : symptôme, impact,
  version touchée.

## 2. Branche ⏸
Propose `hotfix/PROJ-123-slug` créée **depuis le tag ou la branche de prod**, pas
depuis `main`. Crée-la après mon accord.

## 3. Reproduire
Écris d'abord un test de non-régression qui échoue sur la version de prod.
Si la reproduction est impossible, arrête-toi et explique ce qui manque.

## 4. Correctif minimal
Le diff le plus court qui fait passer le test. Aucune dépendance ajoutée ou mise à
jour, aucune migration non réversible, aucun changement de configuration de
sécurité sans accord.

## 5. Vérification
Lint, tests complets, vérification manuelle du scénario du bug.

## 6. Double revue
- Délègue à l'agent `verificateur` : réfuter que le correctif règle le bug sans régression.
- Si le code touche à la sécurité ou aux données : agent `relecteur-securite`.
- Rappelle qu'une **revue humaine** est requise en plus avant fusion.

## 7. Commit et MR/PR ⏸
Commit `fix(<zone>): <résumé>` avec `Refs: PROJ-123`, puis `/pr` vers la branche de
prod. Rien sans mon accord.

## 8. Backport ⏸
Liste les branches qui doivent recevoir le correctif (`main`, `develop`, versions
maintenues) et propose la méthode (`git cherry-pick -x <sha>` ou MR/PR dédiée).
Signale les conflits prévisibles. Propose aussi de lancer `/incident` pour le post-mortem.

## Garde-fous
Aucun déploiement, push, tag ou fusion sans accord explicite. Aucune donnée
personnelle de production recopiée dans le test : données fictives.
