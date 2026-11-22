# CLAUDE.md — application .NET (exemple)

## Projet
- Stack : .NET 8, ASP.NET Core (Web API), Entity Framework Core, SQL Server ou PostgreSQL.
- Lancer : `dotnet run --project src/Api` · Tests : `dotnet test` · Style : `dotnet format` · Build : `dotnet build -warnaserror`

## Conventions
- Projets séparés : `Api`, `Application`, `Domain`, `Infrastructure` ; dépendances orientées vers le domaine.
- Nullable reference types activés ; aucun avertissement ignoré sans justification.
- Code asynchrone de bout en bout (`async`/`await`, `CancellationToken`) ; pas de `.Result` ni `.Wait()`.
- Les DTO sont des `record` ; les entités EF ne sortent jamais de l'API.
- Un changement de modèle = une migration `dotnet ef migrations add`, relue avant commit.
- Tests : xUnit, `WebApplicationFactory` pour les tests d'intégration de chaque nouvel endpoint.

## Sécurité — non négociable
- Politique d'autorisation par défaut stricte (`FallbackPolicy` exigeant un utilisateur authentifié) ; `[AllowAnonymous]` se justifie en revue.
- Autorisation par ressource (`IAuthorizationService`, handlers) : vérifier la propriété de l'objet, pas seulement le rôle.
- Requêtes EF Core via LINQ ; `FromSql` avec interpolation paramétrée ; jamais `FromSqlRaw` avec concaténation.
- Validation côté serveur (`FluentValidation` ou attributs `DataAnnotations`) ; ne pas lier directement une entité (over-posting).
- Secrets : User Secrets en développement, Azure Key Vault ou variables d'environnement ensuite ; jamais dans `appsettings.json` versionné.
- CORS restreint à des origines explicites ; pas de `AllowAnyOrigin` avec identifiants.
- Pas de `BinaryFormatter` ; HTTPS et HSTS activés ; `UseDeveloperExceptionPage` limité au développement.
- Ne pas journaliser de jeton, mot de passe ou donnée personnelle.

## Ne pas faire sans demander
- Modifier une migration déjà appliquée.
- Modifier l'authentification, les politiques d'autorisation ou CORS.
- Ajouter un paquet NuGet.
- Désactiver un avertissement de l'analyseur (`#pragma warning disable`) ou un test (`[Fact(Skip=...)]`).
