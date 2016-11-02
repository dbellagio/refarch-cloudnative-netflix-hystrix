FROM java:8
# VOLUME /tmp
ADD app.jar app.jar
RUN bash -c 'touch /app.jar'

EXPOSE 8383
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
