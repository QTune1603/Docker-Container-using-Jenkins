FROM tomcat:9.0-jdk11-corretto

# Clean up default web applications in Tomcat to avoid path conflicts
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built Java WAR package into Tomcat's deployment folder as the root application
COPY target/hello-world-app.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
