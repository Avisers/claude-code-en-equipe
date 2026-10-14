# CLAUDE.md — <nom du projet>

<!-- Ce fichier est lu par Claude Code à chaque session. Il est versionné et relu
     en revue comme du code. Restez court : chaque ligne doit changer un comportement. -->

## Projet
- Rôle de l'application : <une phrase>
- Stack : <langage, framework et versions exactes>
- Lancer le projet : `<commande>` · Tests : `<commande>` · Lint : `<commande>`

## Conventions
- <nommage, structure des dossiers, style imposé>
- Toute nouvelle fonctionnalité arrive avec ses tests.
- Suivre le style du code existant plutôt que celui des exemples trouvés en ligne.

## Sécurité — non négociable
- Le contrôle d'accès se fait côté serveur, jamais seulement dans l'interface.
- Aucun secret dans le code ni dans un fichier versionné : <où vivent les secrets>.
- Requêtes paramétrées uniquement ; pas de SQL ni de requête construite par concaténation.
- Toute entrée utilisateur est validée côté serveur.

## Ne pas faire sans demander
- Modifier une migration déjà exécutée, la configuration de sécurité, la CI.
- Ajouter une dépendance.
- Supprimer des tests ou les désactiver pour les faire passer.

## Définition de « terminé »
- Lint et tests verts, vérification manuelle faite, diff relu.
