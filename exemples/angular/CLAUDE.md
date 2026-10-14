# CLAUDE.md — application Angular (exemple)

## Projet
- Stack : Angular 20, composants standalone, signals, TypeScript strict.
- Lancer : `ng serve` · Tests : `ng test` · Lint : `ng lint`

## Conventions
- Composants standalone uniquement ; pas de nouveau `NgModule`.
- État local en signals ; RxJS réservé aux flux (HTTP, événements).
- Nouveaux blocs de contrôle (`@if`, `@for`) ; pas de `*ngIf` dans le nouveau code.
- Formulaires réactifs typés.

## Sécurité — non négociable
- Les guards améliorent l'expérience, ils ne protègent rien : l'API vérifie les droits.
- Pas de `bypassSecurityTrust*` ni de `[innerHTML]` sur une donnée utilisateur.
- Aucune clé d'API secrète dans `environment.ts` : tout ce qui est là finit dans le bundle.

## Ne pas faire sans demander
- Ajouter une dépendance npm.
- Désactiver une règle ESLint ou passer un fichier en `any`.
