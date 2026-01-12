# Use a base image with Java (GeoServer requires Java 17+)
FROM openjdk:17-jdk-slim

# Set environment variables
ENV GEOSERVER_VERSION=2.25.0
ENV GEOSERVER_HOME=/opt/geoserver
ENV DATA_DIR=/opt/geoserver/data_dir

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget unzip curl && \
    rm -rf /var/lib/apt/lists/*

# Download and install GeoServer
RUN mkdir -p $GEOSERVER_HOME
WORKDIR $GEOSERVER_HOME
RUN wget https://sourceforge.net/projects/geoserver/files/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-bin.zip/download -O geoserver.zip && \
    unzip geoserver.zip && \
    mv geoserver-$GEOSERVER_VERSION/* $GEOSERVER_HOME && \
    rm -rf geoserver.zip geoserver-$GEOSERVER_VERSION

# Copy your workspace zip from the repo
COPY Sample_Area.zip /tmp/Sample_Area.zip

# Unzip workspace into GeoServer data directory
RUN mkdir -p $DATA_DIR/workspaces && \
    unzip /tmp/Sample_Area.zip -d $DATA_DIR/workspaces && \
    rm /tmp/Sample_Area.zip

# Expose default GeoServer port
EXPOSE 8080

# Set working directory to GeoServer home
WORKDIR $GEOSERVER_HOME

# Start GeoServer in production mode
CMD ["bin/startup.sh"]
