# Politique de sécurité

## Signaler une vulnérabilité

Ne publiez pas de faille dans une issue publique.

- Utilisez le signalement privé de GitHub : onglet **Security** du dépôt, puis **Report a vulnerability**.
- À défaut, écrivez à l'équipe via le formulaire de contact de [avisers.com](https://avisers.com/formation-claude-code/) en indiquant « sécurité » dans l'objet.

Indiquez : le composant touché (hook, commande, workflow, exemple), les étapes de
reproduction, l'impact estimé et, si possible, un correctif proposé. Ne joignez
aucune donnée réelle ni aucun secret.

## Délais visés

| Étape | Délai |
|---|---|
| Accusé de réception | 3 jours ouvrés |
| Première évaluation | 10 jours ouvrés |
| Correctif ou contournement | selon la gravité, au plus 90 jours |

La divulgation est coordonnée : nous publions le correctif et un avis avant
toute divulgation détaillée, et créditons le découvreur s'il le souhaite.

## Périmètre

Concerné : les scripts de hooks (contournement de `garde-secrets.sh`,
`garde-commandes.sh`, `garde-branche.sh`), les workflows CI (injection, fuite de
secret), les modèles de configuration (`managed-settings.json`, `mcp.json.exemple`)
et les `CLAUDE.md` d'exemple qui recommanderaient une pratique dangereuse.

Hors périmètre : les vulnérabilités de Claude Code lui-même (à signaler à
Anthropic) et celles des outils tiers cités.

## Versions supportées

Seule la dernière version majeure reçoit des correctifs.
