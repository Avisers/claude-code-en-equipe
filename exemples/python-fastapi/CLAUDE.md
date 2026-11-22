# CLAUDE.md — application Python FastAPI (exemple)

## Projet
- Stack : Python 3.12, FastAPI, Pydantic v2, SQLAlchemy 2 (async), Alembic, PostgreSQL.
- Lancer : `uvicorn app.main:app --reload` · Tests : `pytest` · Lint : `ruff check .` · Format : `ruff format .` · Types : `mypy app`

## Conventions
- Structure : `app/routers`, `app/services`, `app/models` (SQLAlchemy), `app/schemas` (Pydantic) ; routeurs minces.
- Annotations de types partout ; `mypy` strict sans nouvelle erreur.
- Dépendances d'accès (`Depends`) pour la session de base et l'utilisateur courant.
- Schémas Pydantic distincts en entrée et en sortie (`response_model`) ; jamais le modèle ORM brut.
- Une modification de modèle = une migration `alembic revision --autogenerate`, relue avant commit.
- Tests : `pytest` + `httpx.AsyncClient`, un test par nouvelle route, base de test isolée.

## Sécurité — non négociable
- Chaque route sensible déclare une dépendance d'authentification (`Depends(get_current_user)`) ; vérifier ensuite la propriété de la ressource (anti-IDOR).
- Requêtes SQLAlchemy via l'API d'expression ou paramètres liés ; jamais de f-string dans `text()`.
- Toute entrée passe par un schéma Pydantic ; `extra="forbid"` sur les schémas d'écriture.
- Mots de passe hachés avec Argon2 ou bcrypt (`passlib`/`argon2-cffi`) ; jetons JWT à durée courte, algorithme fixé explicitement.
- Secrets via `pydantic-settings` et variables d'environnement ; jamais dans le code ni dans `.env` versionné.
- CORS restreint (`allow_origins` explicite) ; pas de `*` avec `allow_credentials=True`.
- Pas de `pickle`, `eval`, `exec` ni `yaml.load` sur donnée externe ; pas de `subprocess` avec `shell=True`.
- Pas de `debug=True` ni de documentation OpenAPI ouverte en production si l'API est interne.
- Ne pas journaliser de jeton, mot de passe ou donnée personnelle.

## Ne pas faire sans demander
- Modifier une migration Alembic déjà appliquée.
- Modifier l'authentification, la gestion des jetons ou CORS.
- Ajouter une dépendance (`pyproject.toml`, `requirements`).
- Ajouter `# type: ignore`, `# noqa` ou désactiver un test pour passer.
