---
description: Inventorier la dette technique d'une zone ciblée et proposer des tickets priorisés
argument-hint: <dossier, module ou thème (ex. src/Facturation, « tests lents », « dépendances »)>
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(git shortlog:*), mcp__atlassian__*, mcp__sonarqube__*
---
Zone : $ARGUMENTS

Inventaire **ciblé** : une zone à la fois, pas l'ensemble du dépôt. **Aucun fichier
modifié.**

## 1. Collecter
- Code : duplication, fonctions trop longues, couplage, code mort, `TODO`/`FIXME`,
  tests absents ou fragiles, dépendances obsolètes ou vulnérables.
- Historique : fichiers les plus souvent modifiés et corrigés (`git log --format=
  --name-only -- <zone>`), signe de zone fragile.
- SonarQube si disponible (issues, couverture, hotspots de sécurité) ; sinon, le dire.
- Décisions dans `docs/adr/` que le code ne respecte plus.

## 2. Évaluer

| # | Constat | Preuve (`fichier:ligne`) | Impact (bugs, vitesse, sécurité) | Effort (S/M/L) | Priorité |
|---|---|---|---|---|---|

Priorité = impact élevé et effort faible d'abord. Un constat sans preuve n'entre pas
dans le tableau.

## 3. Proposer des tickets ⏸
Pour les cinq premiers, rédige un ticket au format de `/cadrage` (titre, user
story technique, critères d'acceptation vérifiables, estimation). **Ne crée aucun
ticket Jira ou GitLab sans mon accord explicite.**

Ne propose jamais une réécriture globale : chaque ticket doit être livrable seul et
laisser le code dans un meilleur état.
