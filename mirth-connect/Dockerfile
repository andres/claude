# Stage 1: Download HAPI FHIR JARs via Maven
FROM maven:3.9-eclipse-temurin-17 AS maven-build

WORKDIR /build
COPY pom.xml .

# Download all runtime dependencies into target/hapi-jars/
RUN mvn dependency:copy-dependencies -DoutputDirectory=/build/target/hapi-jars -q

# Stage 2: Mirth Connect with HAPI FHIR on the classpath
FROM nextgenhealthcare/connect:latest

USER root

# Copy all HAPI FHIR JARs into Mirth's custom-lib directory
COPY --from=maven-build /build/target/hapi-jars/ /opt/connect/custom-lib/

# Fix ownership so the mirth user can read the JARs
RUN chown -R mirth:mirth /opt/connect/custom-lib/

USER mirth
