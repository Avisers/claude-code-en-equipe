# CLAUDE.md — application Angular (exemple)

## Projet
- Stack : Angular 20, composants standalone, signals, TypeScript strict.
- Lancer : `ng serve` · Tests : `ng test` · Lint : `ng lint` · Build : `ng build`

## Conventions
- Composants standalone uniquement ; pas de nouveau `NgModule`.
- État local en signals ; RxJS réservé aux flux (HTTP, événements).
- Nouveaux blocs de contrôle (`@if`, `@for`) ; pas de `*ngIf` dans le nouveau code.
- Formulaires réactifs typés.

## Sécurité — non négociable
- Les guards améliorent l'expérience, ils ne protègent rien : l'API vérifie les droits.
- Pas de `bypassSecurityTrust*` ni de `[innerHTML]` sur une donnée utilisateur.
- Les jetons ne vont pas dans `localStorage` ; préférer un cookie `HttpOnly` posé par l'API.
- Aucune clé d'API secrète dans `environment.ts` : tout ce qui est là finit dans le bundle.

## Ne pas faire sans demander
- Ajouter une dépendance npm.
- Désactiver une règle ESLint ou passer un fichier en `any`.

## Hook qualité (`qualite.sh`)
- Par défaut : aucun pour TypeScript (seul `shellcheck` pour les scripts). Le hook tourne hors du bac à sable, il n'exécute donc aucun outil fourni par le dépôt.
- Outils du projet (`node_modules/.bin/eslint`) : uniquement avec `export CLAUDE_QUALITE_OUTILS_PROJET=1`, sur un dépôt de confiance et en local.
- Risque de cette option : ces outils exécutent du code du dépôt (configuration, plugins) ; une branche ou une dépendance piégée s'exécuterait à chaque écriture de Claude.
