---
description: Ouvrir une merge request GitLab ou une pull request GitHub en draft, avec une description structurée
argument-hint: "[PROJ-123] [--ready] [branche cible, défaut : main]"
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git remote:*), Bash(git branch:*), Bash(glab mr create:*), Bash(glab mr view:*), Bash(gh pr create:*), Bash(gh pr view:*)
---
Arguments : $ARGUMENTS

## 1. Préparer
- Détecte la forge d'après `git remote get-url origin` : GitLab (y compris
  auto-hébergé) → `glab` ; `github.com` ou GitHub Enterprise → `gh`. Dans le
  doute, demande.
- Vérifie : arbre propre (`git status`), branche différente de la cible, commits
  présents (`git log <cible>..HEAD`). Si la branche n'est pas poussée, **demande**
  avant de pousser.
- Référence du ticket : argument, sinon nom de branche (`feat/PROJ-123-…`), sinon
  messages de commit. Si aucune, demande.

## 2. Revue locale avant push ⏸
La revue IA se fait ici, dans ma session, jamais en CI (aucune clé d'API sur la forge).
- Lance l'agent `verificateur` sur `git diff <cible>...HEAD` : lint, tests, relecture.
- Si le diff touche authentification, autorisations, requêtes en base, entrées
  utilisateur, secrets, dépendances ou données personnelles : agent
  `relecteur-securite` et skill `revue-securite`.
- Présente les constats classés par gravité. Un constat bloquant arrête `/pr` :
  rien n'est poussé tant qu'il n'est pas corrigé ou explicitement accepté par moi.
- Reporte la synthèse dans « Points d'attention pour la revue ».

## 3. Rédiger la description
```markdown
## Ticket
PROJ-123 — <titre> (lien)

## Changements
- <changement 1, du point de vue du comportement>

## Tests
- Automatiques : <tests ajoutés/modifiés, résultat>
- Manuels : <scénario vérifié, navigateur ou requête>

## Captures
<avant / après pour tout changement visible, sinon « sans objet »>

## Risques
<sécurité, données, migration, performance, compatibilité d'API — ou « faibles », justifié>

## Plan de rollback
<revert de la MR/PR, migration réversible ?, feature flag, données à restaurer>

## Points d'attention pour la revue
<où regarder en priorité>
```

Remplis chaque section à partir du diff (`git diff <cible>...HEAD`) et des
commits ; n'invente aucun résultat de test : ce qui n'a pas été lancé est écrit
« non lancé ».

## 4. Créer ⏸
Montre le titre et la description, puis **attends mon accord**. Ensuite :
- GitLab : `glab mr create --draft --target-branch <cible> --title "<titre>" --description "<texte>"`
- GitHub : `gh pr create --draft --base <cible> --title "<titre>" --body "<texte>"`

Draft par défaut ; `--ready` seulement si je l'ai passé en argument. Rends l'URL créée.

## Garde-fous
- Aucun secret ni donnée personnelle dans la description ou les captures (floute ou
  utilise un compte de test).
- Jamais de push forcé, jamais de fusion, jamais d'approbation.
