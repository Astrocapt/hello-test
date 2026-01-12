FROM tomcat:9-jdk17

# Install unzip utility
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

# Remove default Tomcat webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Download and extract GeoServer WAR from ZIP
WORKDIR /tmp
RUN curl -L -o geoserver.zip https://github.com/Astrocapt/Geoserver/raw/main/geoserver-2.28.1-war.zip && \
    unzip geoserver.zip && \
    mv geoserver.war /usr/local/tomcat/webapps/geoserver.war && \
    rm -rf /tmp/*

# Set GeoServer data directory
ENV GEOSERVER_DATA_DIR=/var/geoserver_data

# Create data directory
RUN mkdir -p ${GEOSERVER_DATA_DIR}

# Download Sample_Area workspace ZIP
RUN curl -L -o /tmp/Sample_Area.zip https://github.com/Astrocapt/hello-test/raw/main/Sample_Area.zip

# Create intelligent startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "=== GeoServer Initialization Script ==="\n\
echo "Data directory: ${GEOSERVER_DATA_DIR}"\n\
\n\
# Check if this is first run\n\
if [ ! -f "${GEOSERVER_DATA_DIR}/.initialized" ]; then\n\
  echo "First run detected. Will initialize GeoServer and inject workspace."\n\
  FIRST_RUN=true\n\
else\n\
  echo "GeoServer already initialized. Starting normally."\n\
  FIRST_RUN=false\n\
fi\n\
\n\
# Start Tomcat\n\
echo "Starting Tomcat..."\n\
catalina.sh start\n\
\n\
# Wait for initialization if first run\n\
if [ "$FIRST_RUN" = true ]; then\n\
  echo "Waiting for GeoServer to initialize (this takes ~120 seconds)..."\n\
  sleep 120\n\
  \n\
  # Check if security directory was created\n\
  if [ -d "${GEOSERVER_DATA_DIR}/security" ]; then\n\
    echo "✓ GeoServer initialized successfully!"\n\
    echo "✓ Security directory found at: ${GEOSERVER_DATA_DIR}/security"\n\
    \n\
    # Inject Sample_Area workspace\n\
    echo "Injecting Sample_Area workspace..."\n\
    \n\
    # Check what is inside Sample_Area.zip\n\
    echo "Contents of Sample_Area.zip:"\n\
    unzip -l /tmp/Sample_Area.zip | head -20\n\
    \n\
    # Create workspaces directory if it does not exist\n\
    mkdir -p ${GEOSERVER_DATA_DIR}/workspaces\n\
    \n\
    # Extract to workspaces directory\n\
    cd ${GEOSERVER_DATA_DIR}/workspaces\n\
    unzip -o /tmp/Sample_Area.zip\n\
    \n\
    # Set proper permissions\n\
    chown -R $(whoami) ${GEOSERVER_DATA_DIR}/workspaces\n\
    \n\
    echo "✓ Sample_Area workspace injected successfully!"\n\
    \n\
    # Mark as initialized\n\
    touch ${GEOSERVER_DATA_DIR}/.initialized\n\
    echo "✓ Marked as initialized"\n\
    \n\
    # Restart GeoServer to recognize new workspace\n\
    echo "Restarting GeoServer to load workspace..."\n\
    catalina.sh stop\n\
    sleep 10\n\
    catalina.sh start\n\
    echo "✓ GeoServer restarted"\n\
  else\n\
    echo "✗ ERROR: Security directory not found!"\n\
    echo "GeoServer may not have initialized correctly."\n\
    echo "Contents of data directory:"\n\
    ls -la ${GEOSERVER_DATA_DIR}\n\
  fi\n\
fi\n\
\n\
echo "=== GeoServer is ready ==="\n\
echo "Access at: http://localhost:8080/geoserver/web/"\n\
echo "Default credentials: admin / geoserver"\n\
\n\
# Keep container running\n\
tail -f /usr/local/tomcat/logs/catalina.out\n\
' > /usr/local/bin/start-geoserver.sh && \
    chmod +x /usr/local/bin/start-geoserver.sh

EXPOSE 8080

CMD ["/usr/local/bin/start-geoserver.sh"]
