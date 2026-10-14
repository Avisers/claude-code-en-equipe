---
name: revue-securite
description: Relecture sécurité du code généré ou modifié. À utiliser avant une pull request qui touche à l'authentification, aux autorisations, aux requêtes en base, aux entrées utilisateur ou aux secrets.
---
# Revue sécurité du code généré

Le code généré par IA compile et passe souvent les tests, mais reproduit des failles
classiques. Passe le code concerné au crible de cette liste.

## 1. Contrôle d'accès
- Chaque route, endpoint ou action vérifie les droits **côté serveur**.
- Un utilisateur ne peut pas accéder à l'objet d'un autre en changeant un identifiant (IDOR).
- Un guard, un bouton masqué ou une route cachée côté front ne comptent pas comme contrôle.

## 2. Injections
- Requêtes SQL, DQL, NoSQL paramétrées ; aucune concaténation de valeur utilisateur.
- Pas de `innerHTML`, `bypassSecurityTrust*`, `|raw` ou équivalent sur une donnée utilisateur.
- Pas d'appel shell construit avec une entrée utilisateur.

## 3. Secrets
- Aucune clé, token ou mot de passe dans le code, les fichiers d'environnement versionnés ou le bundle front.

## 4. Données exposées
- Les réponses d'API ne renvoient que les champs nécessaires (pas l'entité complète).
- Les erreurs ne divulguent ni trace, ni requête, ni chemin.

## 5. Dépendances
- Toute nouvelle dépendance est justifiée, maintenue et sans vulnérabilité connue.

## Restitution
Pour chaque constat : gravité (Critique / Haut / Moyen), `fichier:ligne`, scénario
d'exploitation en une phrase, correctif. Si rien n'est trouvé, dis-le et liste ce qui a été vérifié.
