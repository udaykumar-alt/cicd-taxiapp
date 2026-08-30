FROM tomcat:9

LABEL maintainer="Multicloud"

COPY target/*.war /usr/local/tomcat/webapps/

EXPOSE 8080
