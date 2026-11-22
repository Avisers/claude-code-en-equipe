# Le cycle de développement avec Claude Code

Ce document décrit le cycle complet, du ticket au merge, avec la commande à lancer
à chaque étape, ce que fait l'IA, ce que fait l'humain, et où la validation
humaine est obligatoire.

## Vue d'ensemble

```text
ticket → /cadrage → /ticket → plan ✔ → tests → code → vérif → /pr → CI → revue ✔ → merge ✔
                                 ▲                                          ▲
                        validation humaine                        validation humaine
```

`✔` marque un point de validation humaine : l'IA s'arrête et attend.

## Étape par étape

| # | Étape | Commande | L'IA fait | L'humain fait | Validation |
|---|---|---|---|---|---|
| 1 | Cadrage | `/cadrage PROJ-123` | Lit le ticket, liste les ambiguïtés, propose un découpage | Répond aux questions, tranche le périmètre | Oui : périmètre |
| 2 | Démarrage | `/ticket PROJ-123` | Lit le ticket (Jira ou issue GitLab), crée la branche, explore le code | Vérifie le nom de branche | Non |
| 3 | Plan | (dans `/ticket`) | Propose un plan : fichiers, risques, tests prévus | Relit, corrige, approuve | **Oui : plan** |
| 4 | Tests d'abord | (dans `/ticket`) | Écrit les tests qui échouent (agent `testeur`) | Vérifie qu'ils décrivent le bon comportement | Oui : tests |
| 5 | Implémentation | (dans `/ticket`) | Code jusqu'au vert ; les hooks bloquent secrets, commandes destructives, édition sur `main` | Surveille, interrompt si dérive | Non |
| 6 | Vérification | agent `verificateur` | Rejoue lint, tests, scénario manuel, relit le diff | Contrôle la preuve fournie | Oui : preuve |
| 7 | Revue sécurité | agent `relecteur-securite` | Cherche contrôle d'accès, injection, secrets, fuite de données | Arbitre les constats | Oui si constat |
| 8 | Ouverture | `/pr` | Prépare le commit, pousse, rédige la description depuis le ticket | Relit le diff complet avant de valider | **Oui : push** |
| 9 | CI | automatique | `verif`, `revue-claude` commentent la PR/MR | Lit les retours | Non |
| 10 | Revue | `/revue-pr 42` | Relecture structurée d'une PR d'un collègue | Un relecteur humain approuve | **Oui : approbation** |
| 11 | Merge | outil Git | Rien | Fusionne | **Oui : merge** |

## Cas particuliers

| Situation | Commande | Particularité |
|---|---|---|
| Bug en production | `/incident` puis `/hotfix` | `/incident` lit Sentry (stack, fréquence, release), `/hotfix` part de la branche de prod, change le minimum, ajoute le test de non-régression |
| Décision d'architecture | `/adr` | Rédige un enregistrement de décision, l'agent `architecte` donne un second avis |
| Arrivée d'un développeur | `/onboarding` | Parcours guidé du dépôt à partir de `CLAUDE.md` |
| Dette technique | `/dette` | Inventaire priorisé, jamais de refactor sans ticket |

## Rôles

- **L'IA** propose, écrit, exécute et vérifie dans le périmètre autorisé par `settings.json` et la politique de la DSI.
- **Le développeur** reste l'auteur : il est responsable de chaque ligne fusionnée, même générée.
- **Le relecteur** est un humain différent de l'auteur. La revue Claude s'ajoute à la sienne, jamais à sa place.
- **Le champion** fait évoluer `CLAUDE.md`, les commandes et les hooks (voir [adoption.md](adoption.md)).

## Règles de conduite

1. Pas de plan approuvé, pas de code.
2. Pas de test qui échoue d'abord, pas d'implémentation.
3. Un test supprimé ou désactivé pour passer est un refus de revue.
4. Les hooks ne se contournent pas (`--no-verify` interdit) ; un faux positif se corrige dans le hook, par PR.
5. Toute modification de migration exécutée, de configuration de sécurité ou de CI se demande explicitement.
6. En cas de doute sur une donnée personnelle ou un secret, l'IA s'arrête et le dit.
