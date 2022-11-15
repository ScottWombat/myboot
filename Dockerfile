FROM eclipse-temurin:17 as jre-build

RUN $JAVA_HOME/bin/jlink \
         --add-modules java.base,java.naming,java.desktop,java.compiler,java.logging,java.instrument,java.management,java.security.jgss,java.sql,java.xml,java.rmi,jdk.charsets \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

FROM debian:buster-slim as app-build

ENV JAVA_HOME=/opt/jdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"

WORKDIR application

COPY --from=jre-build /javaruntime $JAVA_HOME
COPY target/myboot-*.jar application.jar

RUN java -Djarmode=layertools -jar application.jar extract

FROM debian:buster-slim

ENV JAVA_HOME=/opt/jdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"

WORKDIR application

COPY --from=jre-build /javaruntime $JAVA_HOME
COPY --from=app-build application/dependencies/ ./
COPY --from=app-build application/spring-boot-loader/ ./
COPY --from=app-build application/snapshot-dependencies/ ./
COPY --from=app-build application/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
