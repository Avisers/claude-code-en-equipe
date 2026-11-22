---
description: Analyser un incident depuis une issue Sentry — stacktrace, hypothèses, reproduction, correctif, post-mortem sans blâme
argument-hint: <URL ou identifiant d'issue Sentry | description de l'incident>
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git log:*), Bash(git blame:*), Bash(git show:*), Bash(git diff:*), mcp__sentry__*, mcp__atlassian__*
---
Incident : $ARGUMENTS

## 1. Collecter
Avec le MCP `sentry` : détails de l'issue, stacktrace, breadcrumbs, tags
(release, environnement, navigateur), fréquence et nombre d'utilisateurs touchés,
première et dernière occurrence, release d'apparition.
Sans MCP, demande-moi de coller la stacktrace.

**Données personnelles** : n'affiche ni ne recopie e-mails, IP, identifiants
utilisateur ou contenus de requête ; résume-les (« 37 utilisateurs, tous sur iOS 18 »).

## 2. Hypothèses
Remonte la stacktrace jusqu'au code (`git blame`, `git log` sur la release
d'apparition). Propose deux ou trois hypothèses classées par probabilité, chacune
avec l'indice qui la soutient et le test qui la réfuterait.

## 3. Reproduire
Écris un test qui reproduit l'erreur. Une hypothèse non reproduite reste une hypothèse.

## 4. Correctif ⏸
Présente le correctif envisagé et attends mon accord. Selon l'urgence, enchaîne
avec `/hotfix` (prod) ou `/ticket` (flux normal). Délègue la réfutation à l'agent `verificateur`.

## 5. Post-mortem sans blâme
Rédige le post-mortem avec ce modèle. On décrit des systèmes et des décisions,
jamais des fautes individuelles ; aucun nom de personne.

```markdown
# Post-mortem — <titre court> (<date>)

## Résumé
<2-3 phrases : quoi, combien de temps, qui a été touché>

## Impact
- Durée : <début → fin, fuseau>
- Utilisateurs touchés : <nombre ou proportion>
- Fonctionnalités dégradées :

## Chronologie
| Heure | Événement |
|---|---|
| | Détection (alerte Sentry, signalement…) |
| | Diagnostic |
| | Correctif déployé |
| | Retour à la normale |

## Cause racine
<mécanisme technique, et pourquoi les garde-fous ne l'ont pas arrêté>

## Ce qui a bien fonctionné

## Ce qui a manqué

## Actions
| Action | Type (prévention / détection / atténuation) | Responsable (rôle) | Échéance | Ticket |
|---|---|---|---|---|
```

## 6. Suites ⏸
Propose : tickets Jira pour les actions, note sur l'issue Sentry, résolution de
l'issue après déploiement. **Rien n'est créé, commenté ni résolu sans mon accord.**
