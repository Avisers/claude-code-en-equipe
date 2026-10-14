# CLAUDE.md — application Symfony (exemple)

## Projet
- Stack : PHP 8.3, Symfony 7, Doctrine ORM, PostgreSQL. API Platform si présent.
- Lancer : `symfony serve` · Tests : `bin/phpunit` · Analyse : `vendor/bin/phpstan analyse` · Style : `vendor/bin/php-cs-fixer fix`

## Conventions
- Contrôleurs minces : la logique métier vit dans des services.
- Une entité modifiée = une migration générée par `bin/console make:migration`, relue avant commit.
- Tests fonctionnels avec `WebTestCase` pour chaque nouvelle route.

## Sécurité — non négociable
- Chaque contrôleur ou opération API Platform porte `#[IsGranted]` ou passe par un voter.
- Requêtes Doctrine via QueryBuilder et paramètres ; jamais de DQL concaténée.
- Les réponses JSON passent par des DTO ou des groupes de sérialisation explicites ; jamais l'entité brute.
- Secrets dans le vault Symfony (`secrets:set`) ou `.env.local`, jamais dans `.env` versionné.

## Ne pas faire sans demander
- Modifier `config/packages/security.yaml`.
- Modifier une migration déjà exécutée.
- Ajouter un bundle ou une dépendance Composer.
