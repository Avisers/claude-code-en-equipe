---
description: Expliquer le dépôt à un nouvel arrivant — architecture, commandes, conventions, où commencer — sans rien modifier
argument-hint: "[zone ou question précise, optionnel]"
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(git shortlog:*), Bash(ls:*)
---
Focus : $ARGUMENTS

Tu présentes ce dépôt à un développeur qui arrive dans l'équipe. **Lecture seule :
aucun fichier modifié, aucune commande qui écrit, installe ou lance un service.**

Sources, dans cet ordre : `CLAUDE.md`, `README.md`, `docs/` (dont `docs/adr/`),
fichiers de build et de dépendances, CI (`.gitlab-ci.yml`, `.github/workflows/`),
arborescence, `.claude/` (commandes, agents, skills).

Rends :
1. **Le produit en une phrase** et ses utilisateurs.
2. **Stack** : langages, frameworks, versions, services externes (base, file,
   Sentry, SonarQube…).
3. **Architecture** : modules principaux et leur rôle, flux d'une requête type,
   en un schéma texte court.
4. **Commandes** : installer, lancer, tester, linter — copiées des sources, pas devinées.
5. **Conventions** : nommage, branches, commits, revue, Definition of Done.
6. **Décisions structurantes** : les ADR à lire en premier.
7. **Outillage Claude Code de l'équipe** : commandes disponibles (`/ticket`,
   `/cadrage`, `/pr`, `/revue-pr`…) et quand les utiliser.
8. **Où commencer** : trois fichiers à lire, un bon premier ticket type.
9. **Zones sensibles** : authentification, paiement, données personnelles,
   migrations — à toucher avec la skill `revue-securite`.

Pour chaque affirmation, cite le fichier source. Ce que tu n'as pas pu établir,
écris-le comme une question à poser à l'équipe. Si un focus est donné, approfondis
cette zone et résume le reste.
