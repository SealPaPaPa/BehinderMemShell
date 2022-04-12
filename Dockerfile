FROM tomcat:9.0.60-jre8-openjdk-slim-buster

RUN mv webapps.dist/* webapps/

ADD MemJNDIExploit.jar /usr/local/tomcat/lib/
ADD inject.jsp /usr/local/tomcat/webapps/ROOT/

EXPOSE 8080

CMD ["catalina.sh", "run"]

