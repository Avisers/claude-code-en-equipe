---
description: Rédiger un Architecture Decision Record au format MADR dans docs/adr/, avec numérotation automatique
argument-hint: <titre de la décision>
allowed-tools: Read, Grep, Glob, Write, Bash(ls:*), Bash(git log:*)
---
Décision : $ARGUMENTS

## 1. Numéroter
Liste `docs/adr/` (crée le dossier s'il n'existe pas). Le numéro est le plus grand
`NNNN` existant + 1, sur quatre chiffres (`0001` si aucun). Nom du fichier :
`docs/adr/NNNN-titre-en-kebab-case.md` (minuscules, sans accent).

## 2. Instruire
- Lis les ADR existants pour repérer une décision liée ou remplacée.
- Lis le code concerné pour décrire le contexte réel, pas un contexte supposé.
- Si les options ou les critères manquent, pose-moi au plus trois questions.

## 3. Rédiger (MADR)
```markdown
---
status: proposé
date: AAAA-MM-JJ
decideurs: <rôles, pas de noms si l'équipe le préfère>
---
# <Titre de la décision>

## Contexte et problème
<situation, contrainte, question à trancher>

## Critères de décision
- <critère 1>

## Options envisagées
- <option A>
- <option B>

## Décision
Option retenue : « <option> », parce que <justification au regard des critères>.

### Conséquences
- Positives :
- Négatives :

### Vérification
<comment on saura que la décision est appliquée : test, règle de lint, revue>

## Avantages et inconvénients des options
### <option A>
- Pour :
- Contre :

## Liens
<ADR remplacé (« Remplace NNNN »), ticket, page Confluence>
```

Le statut reste `proposé` : il passe à `accepté` après revue humaine. Si l'ADR en
remplace un autre, propose la mise à jour du statut de l'ancien (`remplacé par NNNN`).

## 4. Restitution
Écris le fichier, affiche son chemin et rappelle qu'il se relit en MR/PR comme du
code. Aucun commit sans accord.
