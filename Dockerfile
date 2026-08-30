FROM tomcat:9
LABEL maintainer="MultiCloud"
COPY taxi-booking/target/*.war /usr/local/tomcat/webapps/
EXPOSE 8080
