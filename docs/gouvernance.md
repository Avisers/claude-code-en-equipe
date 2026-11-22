# Gouvernance de Claude Code en entreprise

Document à destination de la DSI, du RSSI, du DPO et des responsables d'équipe. Il complète la politique
technique de [`entreprise/`](../entreprise/README.md). Les faits sur Anthropic sont sourcés ; vérifiez-les
contre votre contrat, qui prime. État des sources : novembre 2026.

## 1. Modèle de menace

| Menace | Vecteur | Contrôle |
|---|---|---|
| Fuite de secret vers le modèle | Lecture de `.env`, clés, `~/.aws` ; secret collé dans un prompt | `permissions.deny` géré, hook `garde-secrets.sh`, gitleaks en CI, formation |
| Exécution destructrice | `rm -rf`, `git push --force`, `curl \| sh` | Règles `deny`, `disableBypassPermissionsMode`, bac à sable, branches protégées |
| Injection de prompt | Contenu hostile dans un ticket Jira, une page web, un README, un résultat MCP | Confirmation humaine des actions, MCP en lecture seule quand possible, `allowedMcpServers` |
| Serveur MCP ou plugin malveillant | Paquet `npx` typosquatté, URL non revue | `allowManagedMcpServersOnly`, `strictKnownMarketplaces`, images Docker épinglées |
| Exfiltration réseau | Commande sortante vers un domaine arbitraire | Proxy d'entreprise, `sandbox.network.allowedDomains` |
| Code vulnérable fusionné | Code généré non relu | Revue humaine obligatoire, SonarQube, skill `revue-securite` |
| Dérive de coûts | Boucles d'agents, modèle le plus cher par défaut | Épinglage des modèles, quotas cloud, métrique `claude_code.cost.usage` |
| Transcriptions locales lisibles | `~/.claude/projects/` stocké en clair | Chiffrement disque, `cleanupPeriodDays` |

Références : [Security](https://code.claude.com/docs/en/security),
[Permissions](https://code.claude.com/docs/en/permissions).

### Limites connues des hooks du kit

**Les hooks sont un filet contre les erreurs, pas une frontière de sécurité.** Ils arrêtent les fausses
manœuvres et les raccourcis courants, pas un agent (ou un humain) décidé à les contourner. La vraie frontière,
ce sont les règles `permissions.deny` de `managed-settings.json`, le bac à sable (`sandbox`, qui isole
fichiers et réseau au niveau du système) et des secrets **absents du poste** (coffre, jetons à courte durée).
Branches protégées côté forge et revue humaine complètent le dispositif.

**La protection des secrets repose sur `sandbox.filesystem.denyRead` et sur l'absence de secrets sur le
poste, pas sur le hook.** `garde-commandes.sh` refuse les formes courantes (nom en clair, guillemets ou
antislashs intercalés, jokers `cat .e*v`, `$'…'`, accolades `.e{n,x}v`, `${…}` dans un nom caché sensible),
mais l'analyse lexicale a été arrêtée là, volontairement : elle ne poursuit pas les contournements suivants.

| Contournement hors de portée | Exemple |
|---|---|
| Variable intermédiaire | `x=.env; cat $x` |
| Construction par `$''`, accolades ou `${…}` hors d'un mot commençant comme un nom sensible | `f=$'\x2e'; cat ${f}env`, `cat {.,}env` |
| Concaténation, `eval`, alias | `r=r; m=m; $r$m …` |
| Encodage | base64, hexadécimal, fichier découpé |
| Script écrit puis exécuté | `printf … > a.sh; sh a.sh` |

`ls` est toléré avec des jokers (`ls .e*`, `ls -d .[a-z]*`) : il ne lit que des noms. À l'inverse, la garde
refuse des commandes légitimes qui citent un fichier de secrets ; seule l'initialisation
`cp .env.example .env` (ou `.exemple`, `.sample`, `.dist`) est explicitement autorisée.

| Limite | Exemple de contournement | Contrôle qui prend le relais |
|---|---|---|
| Analyse lexicale de la commande, sans exécution | Commande assemblée par concaténation (`r=r; m=m; $r$m -rf …`), `eval`, alias, script écrit puis lancé | `sandbox`, règles `deny` gérées, revue |
| Contenu encodé | Secret écrit en base64, en hexadécimal ou découpé sur plusieurs écritures | gitleaks en CI sur tout l'historique, rotation des secrets |
| Écritures par Bash | `echo … > fichier`, `sed -i`, `python -c` : ni `garde-secrets.sh` ni `garde-branche.sh` ne les voient | Branches protégées côté forge, gitleaks en CI |
| Lecture de secrets hors liste | Outil de lecture absent de la liste (`dd`, `python -c open()`), fichier de secrets au nom inhabituel | `permissions.deny` gérées, secrets hors du poste (coffre) |
| Levée de `garde-branche` par Bash | `garde-commandes.sh` refuse les écritures visibles vers `.claude/branche-libre` (nom littéral, guillemets, jokers), mais une construction lexicale (`f=branche-; touch .claude/${f}libre`, script écrit puis lancé) crée le fichier sans qu'il voie le nom | **Branches protégées côté forge** (pas de push direct ni forcé sur main/develop, MR obligatoire) : c'est le vrai garde-fou, la garde locale n'est qu'un rappel |
| Masquage du journal | Valeur sensible sans nom révélateur | `OTEL_LOG_TOOL_DETAILS=0`, rétention courte du journal |

Les hooks du projet sont modifiables par quiconque modifie le dépôt : en CI, la revue Claude charge ceux
de la branche cible, jamais ceux de la branche proposée ; sur les postes, voir `allowManagedHooksOnly` dans
[`entreprise/README.md`](../entreprise/README.md).

La clé de la revue IA en CI suit la même logique : sur GitLab, variables masquées, non protégées,
limitées à l'environnement `revue-ia`, protégé avec approbation d'un mainteneur, et job imposé par une
pipeline execution policy ou un `ci_config_path` de conformité, pour que l'auteur d'une MR ne puisse
pas réécrire le job qui reçoit la clé. Détail : en-tête de [`.gitlab-ci.yml`](../.gitlab-ci.yml) et
[`entreprise/README.md`](../entreprise/README.md#revue-ia-en-ci).

## 2. Données envoyées et rétention

Claude Code s'exécute sur le poste et envoie au fournisseur les prompts, les fichiers lus et les sorties
d'outils nécessaires à la tâche, chiffrés en transit (TLS 1.2+).

| Sujet | Offre commerciale (Team, Enterprise, API, Bedrock, Vertex) | Source |
|---|---|---|
| Entraînement | Anthropic n'entraîne pas ses modèles sur le code ou les prompts envoyés sous conditions commerciales, sauf adhésion volontaire (Development Partner Program) | [Data usage](https://code.claude.com/docs/en/data-usage#data-training-policy) |
| Rétention standard | 30 jours côté Anthropic | [Data usage](https://code.claude.com/docs/en/data-usage#data-retention) |
| Zero data retention | Disponible pour Claude Code sur Claude for Enterprise, activée par organisation après éligibilité ; non incluse par défaut | [Zero data retention](https://code.claude.com/docs/en/zero-data-retention) |
| Cache local | Transcriptions en clair dans `~/.claude/projects/`, 30 jours par défaut, réglable par `cleanupPeriodDays` | [Data usage](https://code.claude.com/docs/en/data-usage#data-retention) |
| `/feedback`, `/bug` | Transcription envoyée et conservée 5 ans ; désactivable par `DISABLE_FEEDBACK_COMMAND=1`. Sur Bedrock/Vertex, archive locale seulement | [Data usage](https://code.claude.com/docs/en/data-usage#feedback-using-the-feedback-command) |
| Télémétrie Anthropic | Métriques sans code ni prompt ; désactivée par défaut sur Bedrock et Vertex | [Telemetry services](https://code.claude.com/docs/en/data-usage#telemetry-services) |
| Chiffrement au repos | API : AES-256 ; Bedrock : clés AWS ou KMS client ; Vertex : clés Google ou CMEK | [Data usage](https://code.claude.com/docs/en/data-usage#local-claude-code-data-flow-and-dependencies) |

Conditions de référence : [Commercial Terms](https://www.anthropic.com/legal/commercial-terms),
[Privacy Center](https://privacy.anthropic.com/), [Trust Center](https://trust.anthropic.com).
Les comptes personnels Free/Pro/Max relèvent d'autres règles (entraînement possible) : **interdits pour le code de l'entreprise**.

## 3. RGPD et données personnelles

| Règle | Mise en œuvre |
|---|---|
| Pas de données personnelles réelles dans les prompts ni dans les dépôts ouverts à Claude | Jeux de données anonymisés ou synthétiques en dev ; dumps de prod interdits sur les postes |
| Sous-traitance encadrée | DPA signé avec le fournisseur retenu (Anthropic, AWS ou Google) ; inscription au registre des traitements (art. 30) |
| Transferts hors UE | Préférer une région UE (Bedrock `eu-*`, Vertex `eu`) ; sinon clauses contractuelles types et analyse d'impact du transfert |
| Minimisation | `OTEL_LOG_USER_PROMPTS=0` et `OTEL_LOG_TOOL_DETAILS=0` : le collecteur interne ne stocke pas le contenu des échanges |
| Durée de conservation | `cleanupPeriodDays` géré ; rétention du collecteur OTel fixée par la DSI |
| AIPD | À conduire si l'outil touche des dépôts contenant des données personnelles (logs, fixtures, exports) |

## 4. Classification des dépôts

| Classe | Exemples | Claude Code | Fournisseur |
|---|---|---|---|
| C0 — Public | Open source, documentation publique | Autorisé | Tous |
| C1 — Interne | Applications métier standard, outillage | Autorisé, politique gérée obligatoire | Tous, contrat commercial |
| C2 — Confidentiel | Cœur métier, algorithmes différenciants, code client sous NDA | Autorisé sur validation du responsable, région UE, ZDR recommandé | Bedrock/Vertex UE ou API avec ZDR |
| C3 — Secret / réglementé | Données de santé, défense, secrets de chiffrement, dépôts d'infra de prod avec secrets | **Interdit** | — |

La classe est déclarée dans le `CLAUDE.md` du dépôt et vérifiée en revue. Un dépôt qui contient des secrets
en clair est C3 tant qu'il n'est pas assaini.

## 5. Choix du fournisseur

| Critère | API Anthropic (Team/Enterprise) | Amazon Bedrock | Google Cloud Agent Platform (Vertex) |
|---|---|---|---|
| SSO / identité | SSO claude.ai, `forceLoginMethod`, `forceLoginOrgUUID` | IAM Identity Center, rôles | IAM Google, fédération d'identité |
| Résidence UE | Selon contrat | Régions `eu-*`, préfixe `eu.` | Multirégion `eu`, régions `europe-*` |
| ZDR | Sur éligibilité (Enterprise) | Selon politique AWS Bedrock | Selon politique Google |
| Facturation | Anthropic | Facture AWS existante | Facture GCP existante |
| Paramètres gérés côté serveur | Oui (console claude.ai) | Non : fichier ou MDM | Non : fichier ou MDM |
| Fonctions | Toutes | Pas de WebSearch | Selon modèles et régions |
| Configuration | — | [`bedrock.env.exemple`](../entreprise/bedrock.env.exemple) | [`vertex.env.exemple`](../entreprise/vertex.env.exemple) |

Sources : [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock),
[Google Cloud Agent Platform](https://code.claude.com/docs/en/google-vertex-ai),
[Network configuration](https://code.claude.com/docs/en/network-config).
Règle simple : l'organisation déjà engagée sur un cloud y reste, pour réutiliser IAM, facturation, journaux et région.

## 6. Coûts et quotas

| Levier | Action |
|---|---|
| Épingler les modèles | `ANTHROPIC_MODEL` sur Sonnet par défaut ; sans épinglage, Bedrock/Vertex démarrent sur Opus, facturé plus cher |
| Restreindre | `availableModels` + `enforceAvailableModels` dans la politique gérée |
| Isoler | Compte AWS ou projet GCP dédié à Claude Code |
| Plafonner | Quotas de jetons Bedrock / Vertex, budgets et alertes cloud |
| Mesurer | Collecteur OTel : `claude_code.cost.usage`, `claude_code.token.usage`, ventilés par `OTEL_RESOURCE_ATTRIBUTES` (équipe, centre de coût) — [Monitoring](https://code.claude.com/docs/en/monitoring-usage) |
| Revoir | Revue FinOps mensuelle : coût par équipe, par PR fusionnée, taux d'acceptation (`claude_code.code_edit_tool.decision`) |

## 7. Revue humaine obligatoire

- Aucun code généré n'est fusionné sans relecture d'un humain qui n'est pas l'auteur de la demande.
- Branches protégées sur GitLab et GitHub : pas de push direct, pas de force push, CI verte requise
  (gitleaks, lint, tests, SonarQube Quality Gate).
- L'auteur de la MR/PR reste responsable du code, quelle que soit la part écrite par l'outil.
- Modifications sensibles (authentification, paiement, migrations, IAM, CI) : deux relecteurs.

## 8. Propriété intellectuelle et licences

| Point | Position |
|---|---|
| Propriété des sorties | Les conditions commerciales d'Anthropic attribuent les sorties au client ; vérifiez la clause dans votre contrat ([Commercial Terms](https://www.anthropic.com/legal/commercial-terms)) |
| Indemnisation | Les Commercial Terms prévoient une défense du client contre certaines réclamations de droit d'auteur liées à un usage autorisé ; portée exacte à valider par le juridique |
| Code tiers reproduit | Un extrait long et reconnaissable d'un projet tiers garde sa licence : scan de licences (SCA) en CI |
| Dépendances proposées | Toute nouvelle dépendance passe la revue habituelle (licence, maintenance, CVE) |
| Code client | Le code d'un client n'est soumis à l'outil que si le contrat le permet (classe C2 au minimum) |

## 9. Journal d'audit

| Source | Contenu | Rétention conseillée |
|---|---|---|
| Collecteur OTel interne | Sessions, coûts, jetons, décisions d'outils, erreurs d'API ; pas de prompt (`OTEL_LOG_USER_PROMPTS=0`) | 12 mois |
| Fournisseur cloud | AWS CloudTrail (appels Bedrock), Google Cloud Audit Logs (Vertex) | Politique de l'entreprise |
| Console Anthropic | Journaux d'administration et d'usage du forfait Enterprise | Selon offre |
| Forge | Historique des MR/PR, approbations, pipelines GitLab/GitHub | Durée de vie du dépôt |
| MDM | Version déployée de `managed-settings.json` par poste | 12 mois |

## 10. Procédure d'incident : fuite de secret

| Étape | Délai | Action |
|---|---|---|
| 1. Révoquer | Immédiat | Révoquer ou faire tourner le secret chez son émetteur (cloud, forge, base, API). Ne pas attendre de savoir s'il a été exploité |
| 2. Contenir | < 1 h | Supprimer le secret du code ; s'il a été poussé, réécrire l'historique en coordination avec la forge et purger les caches ; supprimer la transcription locale concernée dans `~/.claude/projects/` |
| 3. Évaluer | < 24 h | Le secret a-t-il quitté le poste (prompt, sortie d'outil envoyée au modèle, MCP, push) ? Consulter les journaux du service exposé |
| 4. Notifier | Selon gravité | RSSI ; DPO si données personnelles en jeu (notification CNIL sous 72 h si violation de données, art. 33 RGPD) ; fournisseur si vous avez besoin d'une purge côté serveur |
| 5. Corriger | < 1 semaine | Ajouter le motif à `garde-secrets.sh`, aux règles `deny` gérées et à gitleaks ; post-mortem sans blâme |

Pour un compte en zero data retention, rien n'est conservé côté serveur après la réponse ; en rétention
standard, contactez le fournisseur pour la suppression anticipée.
