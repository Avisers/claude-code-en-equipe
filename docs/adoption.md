# Adopter Claude Code dans une organisation

Déploiement par vagues : on prouve la valeur et la sûreté à petite échelle avant
d'élargir. Ne passez à la vague suivante que si les critères de la vague en cours
sont remplis.

## Vagues

| Vague | Périmètre | Durée indicative | Objectif |
|---|---|---|---|
| 1. Pilote | 5 développeurs volontaires, 1 ou 2 projets | 4 à 6 semaines | Valider le kit, mesurer, trouver les frictions |
| 2. Équipe | Une ou plusieurs équipes complètes (10 à 40 devs) | 2 à 3 mois | Standardiser `CLAUDE.md`, commandes et hooks |
| 3. Organisation | Toutes les équipes | continu | Gouvernance, coûts, support par les champions |

### Vague 1 : pilote

- Choisir 5 développeurs de profils variés (un senior, un junior, un sceptique).
- Installer le kit, déployer `entreprise/managed-settings.json` par MDM dès le début.
- Fixer la ligne de base des métriques **avant** de commencer.
- Point hebdomadaire de 30 minutes : frictions, faux positifs des hooks, idées.

**Critères de passage à la vague 2**

- Aucun incident de sécurité attribuable à l'usage (secret commité, accès non contrôlé fusionné).
- Temps de cycle stable ou en baisse, taux de rework non dégradé.
- Au moins 4 pilotes sur 5 disent vouloir continuer.
- `CLAUDE.md` du projet relu et stabilisé (plus de modification hebdomadaire).
- Coût par développeur connu et accepté.

### Vague 2 : équipe

- Un `CLAUDE.md` par dépôt, partir de `exemples/` pour la stack.
- Brancher les MCP utiles (`entreprise/mcp.json.exemple`) : tickets, Sentry, SonarQube.
- Activer la CI de revue (`revue-claude`) en commentaire, sans blocage au début.
- Formation de 2 demi-journées par équipe (voir ci-dessous).

**Critères de passage à la vague 3**

- Au moins 70 % des développeurs de l'équipe actifs chaque semaine.
- Au moins 2 champions identifiés et disponibles.
- Journal d'audit et télémétrie OpenTelemetry en place.
- Revue de sécurité du déploiement faite avec la DSI et le DPO.

### Vague 3 : organisation

- Politique centrale versionnée, mise à jour par PR relue par la DSI.
- Budget et alertes de coût par équipe.
- Communauté de champions, revue trimestrielle des commandes et des hooks.

## Métriques

Mesurez avant, pendant et après ; comparez à la ligne de base, pas à des promesses.

| Métrique | Définition | Source | Lecture |
|---|---|---|---|
| Fréquence de déploiement (DORA) | Déploiements en production par semaine | CI/CD | Doit monter ou rester stable |
| Délai de mise en production (DORA) | Du premier commit au déploiement | Git + CI | Doit baisser |
| Taux d'échec des changements (DORA) | Part des déploiements causant un incident | Sentry, tickets | Ne doit pas monter |
| Temps de rétablissement (DORA) | Durée moyenne d'un incident | Sentry, astreinte | Doit baisser |
| Temps de cycle | Ticket en cours → merge | Jira / GitLab | Doit baisser |
| Taux de rework | Part des lignes réécrites sous 21 jours ou des PR renvoyées en correction | Git, revue | Signal de qualité : ne doit pas monter |
| Incidents sécurité | Secrets exposés, failles trouvées en revue ou en production | Gitleaks, SonarQube, revue | Cible : zéro en production |
| Coût par développeur | Dépense mensuelle modèle ÷ développeurs actifs | Facturation, OTel | À comparer au temps gagné |
| Satisfaction | Enquête courte tous les mois | Formulaire | Complément qualitatif |

Piège classique : mesurer le volume de code produit. Plus de code n'est pas un
meilleur résultat.

## Formation

| Public | Contenu | Format |
|---|---|---|
| Tous les développeurs | Prise en main, `CLAUDE.md`, commandes du kit, ce que l'IA ne doit pas faire seule | 1 demi-journée, sur le code de l'équipe |
| Relecteurs | Relire du code généré, `/revue-pr`, pièges de sécurité | 1 demi-journée |
| Champions | Écrire des commandes, agents et hooks, lire la télémétrie | 1 journée |
| Encadrement et DSI | Gouvernance, métriques, risques | 2 heures |

La [formation Avisers](https://avisers.com/formation-claude-code/) couvre ce
programme, sur le code réel de l'équipe.

## Champions

Un champion par équipe d'une dizaine de développeurs, 10 % de son temps.
Il tient `CLAUDE.md` à jour, trie les demandes d'évolution du kit, anime un point
mensuel, remonte les frictions et les faux positifs des hooks, et aide les
nouveaux. Sans champion, le kit se périme en un trimestre.

## Anti-patterns

| Anti-pattern | Conséquence | Alternative |
|---|---|---|
| Déployer à tous le même jour | Aucun retour exploitable, rejet | Pilote puis vagues |
| Imposer sans former | Usages divergents, défiance | Formation + champions |
| `CLAUDE.md` jamais relu | Contexte faux, code faux | Relecture en PR comme du code |
| Fusionner sans relecture humaine | Failles et dette invisibles | Approbation humaine obligatoire |
| Mesurer les lignes produites | Mauvaises incitations | DORA, rework, incidents |
| Désactiver les hooks quand ils gênent | Garde-fous vides | Corriger le hook par PR |
| Pas de budget ni d'alerte de coût | Facture surprise | OTel + plafonds par équipe |
| Donner tous les droits aux agents | Actions destructives | Permissions minimales, `garde-commandes.sh` |
| Ignorer la conformité | Blocage tardif par le DPO | Associer DSI et DPO dès le pilote (voir [gouvernance](gouvernance.md)) |
