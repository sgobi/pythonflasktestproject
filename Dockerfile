FROM jenkins/jenkins:lts
USER root

# Install Docker inside the Jenkins container
RUN apt-get update && apt-get install -y docker.io \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure the Jenkins user can use Docker (by adding it to the Docker group)
RUN usermod -aG docker jenkins

# Optionally, ensure the Docker service is started automatically
# Note: You may need to handle Docker differently in Jenkins containers since it doesn't use systemd
RUN systemctl enable docker || true

# Expose the port Jenkins uses
EXPOSE 8080
