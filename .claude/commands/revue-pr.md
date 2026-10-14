---
description: Relire la branche courante avant d'ouvrir une pull request
---
Relis le diff de la branche courante par rapport à `main` (`git diff main...HEAD`).

Pour chaque fichier modifié, vérifie :
1. que le changement correspond au ticket et à rien d'autre ;
2. les conventions de `CLAUDE.md` ;
3. la présence de tests pour tout nouveau comportement ;
4. la sécurité : contrôle d'accès côté serveur, entrées validées, requêtes paramétrées, aucun secret.

Rends une liste de constats classés **Bloquant / À corriger / Suggestion**, chacun avec
`fichier:ligne` et le correctif proposé. Ne modifie aucun fichier.
