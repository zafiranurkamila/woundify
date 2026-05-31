Short report — Java runtime upgrade analysis

Project: woundify/backend
Date: 2026-05-31

Summary:
- Current `java.version` in `backend/pom.xml`: 17
- Spring Boot parent: 3.3.0
- No explicit `maven-compiler-plugin` configuration found (parent manages compiler plugin)
- Build command run: `mvn -f backend/pom.xml -DskipTests package`
- Build result: artifact produced at `backend/target/woundify-backend-0.0.1-SNAPSHOT.jar`

Findings and next steps:
- The project currently targets Java 17 and builds successfully with the environment's default Java.
- To perform a Java runtime upgrade (for example to Java 21 or Java 25), the user must choose the target LTS.
- After target selection we will:
  - Update `<java.version>` property in `backend/pom.xml` to the chosen value.
  - Add or adjust `maven-compiler-plugin` configuration if necessary (set `release`/`source`/`target`).
  - Verify build tool compatibility and CI/docker config.
  - Run full test suite and fix any test failures.

Actions taken:
- Analyzed `backend/pom.xml` and detected `java.version=17`.
- Ran `mvn -DskipTests package` and confirmed a jar was produced.
- Saved analysis and build output to `.github/modernize/java-upgrade-report-20260531170806/`.

Repository changes made: none (no files modified/committed).

Please choose the target Java LTS to proceed with automated pom updates and commits:
- Java 17 (keep current)
- Java 21
- Java 25
