# Install Docker inside the Jenkins container
RUN apt-get update && apt-get install -y docker.io \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optionally, ensure the Docker service is started automatically (for newer Jenkins versions)
RUN systemctl enable docker


# Use an official Python base image
FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Copy only requirements first (for better caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app files
COPY . .

# Expose the port Flask runs on
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
