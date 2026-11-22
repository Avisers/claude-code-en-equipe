# Déploiement entreprise

Fichiers destinés à la DSI pour imposer une politique Claude Code commune sur tous les postes.
Les clés utilisées sont celles de la documentation officielle
([paramètres gérés](https://code.claude.com/docs/en/managed-settings),
[exemple d'organisation](https://code.claude.com/docs/en/settings-example#an-organizations-managed-settings)).

| Fichier | Rôle | Destination |
|---|---|---|
| `managed-settings.json` | Politique imposée : permissions refusées, mode bypass désactivé, MCP autorisés, télémétrie OTel, rétention locale | Répertoire système (ci-dessous) ou MDM |
| `mcp.json.exemple` | Serveurs MCP Jira/Confluence, GitLab, GitHub, Sentry, SonarQube, jetons par `${VAR}` | Copier en `.mcp.json` à la racine du projet |
| `bedrock.env.exemple` | Variables pour Amazon Bedrock | Bloc `env` géré ou environnement du poste |
| `vertex.env.exemple` | Variables pour Google Cloud Agent Platform (ex-Vertex AI) | Idem |
| `otel.env.exemple` | Export des métriques d'usage et de coûts vers le collecteur interne | Bloc `env` de `managed-settings.json` |

Gouvernance (menaces, données, RGPD, coûts, incidents) : [`docs/gouvernance.md`](../docs/gouvernance.md).

## Où déployer `managed-settings.json`

| Système | Fichier | Équivalent MDM |
|---|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` | Profil de configuration, domaine `com.anthropic.claudecode` (Jamf, Kandji, Intune) |
| Linux et WSL | `/etc/claude-code/managed-settings.json` | Paquet ou outil de gestion de configuration (Ansible, Puppet) |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` | Valeur `Settings` (REG_SZ, JSON) sous `HKLM\SOFTWARE\Policies\ClaudeCode` (Intune, GPO) |

- Un dossier `managed-settings.d/` à côté du fichier accepte des fragments `*.json` fusionnés : utile quand
  sécurité, plateforme et FinOps possèdent chacun une partie de la politique.
- `managed-mcp.json`, dans le même répertoire, impose la liste exacte des serveurs MCP.
- Le MDM est relu au démarrage puis toutes les 30 minutes. La clé HKCU (modifiable par l'utilisateur) n'est
  jamais un contrôle de sécurité.
- Avec un forfait Team/Enterprise, la même politique peut être livrée depuis la console claude.ai
  ([paramètres gérés côté serveur](https://code.claude.com/docs/en/server-managed-settings)).
- Un fichier géré qui n'est pas un JSON valide **empêche Claude Code de démarrer** : validez avec `jq .` avant diffusion.

## Hiérarchie de priorité

| Rang | Source | Qui la modifie |
|---|---|---|
| 1 | Paramètres gérés (serveur claude.ai > MDM/HKLM > fichiers système > HKCU) | DSI |
| 2 | Ligne de commande `--settings` | Développeur, pour une session |
| 3 | `.claude/settings.local.json` | Développeur, pour un projet |
| 4 | `.claude/settings.json` (versionné, ce kit) | Équipe |
| 5 | `~/.claude/settings.json` | Développeur |

Les listes (`permissions.deny`, `hooks`…) **se cumulent** entre niveaux : les règles du kit s'ajoutent à celles de
la DSI. Source : [Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence).

## Choix faits dans la politique fournie

| Clé | Valeur | Pourquoi |
|---|---|---|
| `permissions.disableBypassPermissionsMode` | `"disable"` | Supprime le mode qui exécute tout sans confirmation |
| `permissions.deny` | `.env`, `.envrc`, `credentials.json`, clés, `~/.ssh`, `~/.aws`, `curl … \| sh`, `rm -rf` / `rm -fr` / `rm -r -f`, `git push --force` | Lecture de secrets et commandes destructrices |
| `allowManagedMcpServersOnly` + `allowedMcpServers` | URL et commandes exactes | Seuls les serveurs MCP validés se chargent ; un nom de serveur n'est pas un contrôle |
| `disableClaudeAiConnectors` | `true` | Pas de connecteurs claude.ai non revus par la DSI |
| `allowManagedHooksOnly` | `false` | Laisse fonctionner les hooks du kit (`garde-secrets.sh`, `garde-commandes.sh`…), livrés dans chaque dépôt. Voir ci-dessous pour passer à `true` |
| `allowManagedPermissionRulesOnly` | `false` | Idem pour les règles du kit ; `true` n'applique plus que les règles de la DSI |
| `sandbox.enabled` + `allowUnsandboxedCommands: false` | `true` / `false` | Les commandes Bash tournent dans le bac à sable du système, sans repli hors bac à sable ; posée en politique gérée, elle rend le bac à sable obligatoire et Claude Code ignore les assouplissements du projet (`excludedCommands`, `allowWrite`, `allowedDomains`). C'est la vraie frontière, les hooks ne sont qu'un filet |
| `sandbox.failIfUnavailable` | `true` | Claude Code refuse de démarrer si le bac à sable ne peut pas tourner (bubblewrap absent sous Linux, par exemple) |
| `sandbox.filesystem.denyRead` | `~/.ssh`, `~/.aws`, `~/.npmrc`…, puis `~/**/.env`, `~/**/.envrc`, `~/**/credentials.json`… | Identifiants du poste et fichiers de secrets des projets illisibles par les commandes Bash, même via un script. Format de la doc : `~/` relatif au home, jokers `**` acceptés (exemple officiel `~/**/.env`) ; `.` ne vaut la racine du projet qu'en paramètres de projet, d'où des motifs sous `~` en politique gérée — les dépôts hors du home ne sont pas couverts. `denyRead` ne s'applique pas à l'outil Read (couvert par `permissions.deny`) ni aux hooks, qui tournent hors du bac à sable |
| `sandbox.network.allowedDomains` | forge, registres npm et PyPI | Sortie réseau des commandes limitée à ces domaines ; à compléter selon vos registres internes. Source : [Sandboxing](https://code.claude.com/docs/en/sandboxing) |
| `cleanupPeriodDays` | `14` | Les transcriptions locales (`~/.claude/projects/`, en clair) sont purgées après 14 jours |
| `env` | OTel + `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | Télémétrie vers votre collecteur, pas de trafic non essentiel vers Anthropic |

Adaptez les URL `*.exemple.interne`. Le détail des gardes ci-dessous complète le tableau.

### Bac à sable : prérequis des postes

`sandbox.failIfUnavailable` vaut `true` : un poste sans bac à sable fonctionnel **ne démarre pas** Claude Code,
au lieu de lancer les commandes sans isolation. Prérequis ([Sandboxing](https://code.claude.com/docs/en/sandboxing)) :

| Système | À installer |
|---|---|
| macOS | Rien : Seatbelt est intégré au système |
| Linux Ubuntu/Debian | `sudo apt-get install bubblewrap socat` |
| Linux Fedora | `sudo dnf install bubblewrap socat` |
| WSL2 | Comme la distribution Linux utilisée |
| WSL1, Windows natif | Non pris en charge : passer à WSL2 (`wsl -l -v` donne la version) |

Redémarrez Claude Code après l'installation ; `/sandbox` (onglet des dépendances) montre ce qui manque.
Messages attendus : `Sandboxing requires WSL2` sous WSL1 ; sous Ubuntu, `Ubuntu's AppArmor restriction
on user namespaces stops bubblewrap here` (restriction AppArmor à lever par la DSI). Le texte exact de l'arrêt
au démarrage n'est pas cité par la documentation : relevez-le sur un poste pilote avant diffusion.

Dérogation : ticket au RSSI (poste, motif, durée). Si elle est accordée, la DSI dépose sur ce seul poste un
fragment `managed-settings.d/50-derogation-sandbox.json` contenant `{"sandbox": {"failIfUnavailable": false}}`,
avec une date d'expiration consignée dans le ticket, puis le retire à échéance. Le poste exécute alors
Bash sans isolation : seules les règles `deny` et les hooks le protègent.

### Images MCP épinglées par digest

Les images Docker de `allowedMcpServers` et de `mcp.json.exemple` sont épinglées par digest
(`image:tag@sha256:…`, relevé le 2026-11-21 sur le registre) : un tag comme `latest` peut être repoussé
par l'éditeur, un digest non. Pour mettre à jour, relevez le nouveau digest
(`docker buildx imagetools inspect <image>:<tag>` ou `crane digest <image>:<tag>`) et mettez à jour les
deux fichiers ensemble : la commande doit être identique au caractère près, sinon le serveur est refusé.

### Serveurs MCP : sources vérifiées le 2026-11-22

| Serveur | Valeur retenue | Source |
|---|---|---|
| GitLab | `https://<instance>/api/v4/mcp`, HTTP, OAuth (scope `mcp`) ou PAT à grain fin ; GA depuis GitLab 19.5, à autoriser par un admin ou propriétaire de groupe. Les project/group access tokens sont refusés (403) | [GitLab MCP server](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_server/) |
| GitHub | `https://api.githubcopilot.com/mcp/`, en-tête `Authorization: Bearer <PAT>` | [github/github-mcp-server](https://github.com/github/github-mcp-server) |
| Sentry | `https://mcp.sentry.dev/mcp` (restreignable à `/mcp/<org>/<projet>`) | [mcp.sentry.dev](https://mcp.sentry.dev/) |
| Jira/Confluence Server ou Data Center | `ghcr.io/sooperset/mcp-atlassian:0.24.7`, variables `JIRA_PERSONAL_TOKEN` / `CONFLUENCE_PERSONAL_TOKEN` (projet communautaire) | [sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian) |
| SonarQube | Image officielle `sonarsource/sonarqube-mcp:2026.5.1`, variables `SONARQUBE_TOKEN` + `SONARQUBE_URL` (serveur) ou `SONARQUBE_ORG` (Cloud). **Corrigé** : `mcp/sonarqube` (copie du catalogue Docker, tag `latest` seul) remplacé par l'image de l'éditeur | [SonarSource/sonarqube-mcp-server](https://github.com/SonarSource/sonarqube-mcp-server) |

### `allowManagedHooksOnly` : pourquoi `false`, et comment passer à `true`

Avec `true`, seuls les hooks définis dans la politique gérée s'exécutent : ceux du kit, déclarés dans
`.claude/settings.json` de chaque dépôt, seraient ignorés et les gardes disparaîtraient. Avec `false`,
en revanche, un dépôt peut aussi retirer ou affaiblir ses propres hooks. Pour passer à `true` :

1. Déployez les scripts de `.claude/hooks/` sur les postes, dans un répertoire système en lecture seule
   pour l'utilisateur (ex. `/etc/claude-code/hooks/`, `/Library/Application Support/ClaudeCode/hooks/`).
2. Recopiez le bloc `hooks` de `.claude/settings.json` dans `managed-settings.json`, en remplaçant
   `"$CLAUDE_PROJECT_DIR"/.claude/hooks/…` par ces chemins absolus.
3. Mettez `allowManagedHooksOnly` à `true`, validez avec `jq .`, testez sur un poste pilote (`/hooks`
   doit lister les hooks gérés), puis diffusez.
 Les règles `Bash(...)` filtrent la commande **telle qu'écrite** :
elles ne remplacent ni le bac à sable (`sandbox`) ni la revue humaine
([limites](https://code.claude.com/docs/en/permissions#bash-rule-limits)).

## Revue IA : en local, pas en CI

La revue Claude tourne dans la session du développeur, avant push (`/pr`, étape 2) : agents
`verificateur` et `relecteur-securite` sur le diff local. Aucune clé d'API n'est stockée sur la forge,
aucun job CI n'appelle de modèle : la CI ne fait que des vérifications déterministes (`verif`).

## Vérifier sur un poste

```bash
claude doctor            # entrées rejetées
claude                   # puis /status : la ligne « Setting sources » doit citer la source gérée
```

## Réseau d'entreprise

Proxy (`HTTPS_PROXY`, `NO_PROXY`), AC interne (`NODE_EXTRA_CA_CERTS`), mTLS (`CLAUDE_CODE_CLIENT_CERT`,
`CLAUDE_CODE_CLIENT_KEY`) : placez-les dans le bloc `env` géré, seul moyen d'atteindre aussi les agents
en arrière-plan. Pas de proxy SOCKS. Domaines à autoriser : voir
[Network access requirements](https://code.claude.com/docs/en/network-config#network-access-requirements).
Avec Bedrock ou Vertex, le trafic modèle part vers votre cloud ; seul le contrôle de domaine de WebFetch
appelle encore `api.anthropic.com` (désactivable par `skipWebFetchPreflight`).
