# CLAUDE.md — application Java Spring Boot (exemple)

## Projet
- Stack : Java 21, Spring Boot 3.x, Spring Security, Spring Data JPA, Flyway, PostgreSQL, Maven (ou Gradle).
- Lancer : `./mvnw spring-boot:run` · Tests : `./mvnw verify` · Style : `./mvnw spotless:apply` · Analyse : `./mvnw sonar:sonar`

## Conventions
- Architecture en couches : `controller` → `service` → `repository` ; pas de logique métier dans les contrôleurs.
- Injection par constructeur uniquement ; pas d'`@Autowired` sur un champ.
- Les `record` servent de DTO d'entrée et de sortie ; les entités JPA ne sortent jamais de la couche service.
- Une modification de schéma = un nouveau script Flyway `V<n>__description.sql`, relu avant commit.
- Tests : JUnit 5 + Mockito pour les services, `@WebMvcTest` et `@DataJpaTest` (Testcontainers) pour le reste ; un test par nouvelle route.

## Sécurité — non négociable
- Chaque endpoint est protégé côté serveur : `@PreAuthorize` ou règle explicite dans `SecurityFilterChain` ; la règle par défaut est `anyRequest().authenticated()`.
- Vérifier l'appartenance de la ressource à l'utilisateur (anti-IDOR), pas seulement son rôle.
- Requêtes JPA/JDBC paramétrées (`:param`, `@Param`, `JdbcClient`) ; jamais de JPQL ou SQL concaténé.
- Entrées validées par Bean Validation (`@Valid`, `@NotNull`, `@Size`) sur chaque DTO.
- CSRF actif pour les sessions ; si API sans état, le justifier dans le code.
- Pas de `spring-boot-starter-actuator` exposé sans authentification ; seuls `health` et `info` sont publics.
- Pas de désérialisation Java native (`ObjectInputStream`) sur donnée externe ; `FAIL_ON_UNKNOWN_PROPERTIES` actif pour Jackson.
- Mots de passe hachés avec `BCryptPasswordEncoder` ou Argon2 ; jamais de log de donnée personnelle ou de jeton.
- Secrets via variables d'environnement ou coffre (Vault, Secrets Manager), jamais dans `application.yml` versionné.

## Ne pas faire sans demander
- Modifier une migration Flyway déjà exécutée.
- Modifier la configuration Spring Security ou CORS.
- Ajouter une dépendance Maven/Gradle.
- Passer `spring.jpa.hibernate.ddl-auto` à autre chose que `validate` ou `none`.
- Supprimer ou désactiver un test (`@Disabled`) pour le faire passer.

## Hook qualité (`qualite.sh`)
- Par défaut : aucun pour Java (seul `shellcheck` pour les scripts). Le hook tourne hors du bac à sable, il n'exécute donc aucun outil fourni par le dépôt.
- Outils du projet (`mvn spotless:check` / `checkstyle:check`, `./gradlew spotlessCheck`) : uniquement avec `export CLAUDE_QUALITE_OUTILS_PROJET=1`, sur un dépôt de confiance et en local.
- Risque de cette option : ces outils exécutent du code du dépôt (configuration, plugins) ; une branche ou une dépendance piégée s'exécuterait à chaque écriture de Claude.
