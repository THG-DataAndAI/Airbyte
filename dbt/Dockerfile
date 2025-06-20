FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /dbt

# Install dbt
RUN pip install --no-cache-dir \
    dbt-core==1.7.4 \
    dbt-postgres==1.7.4 \
    dbt-bigquery==1.7.4

# Create necessary directories
RUN mkdir -p /dbt/models/staging /dbt/models/marts /dbt/profiles

# Copy dbt project files
COPY dbt_project.yml /dbt/
COPY profiles/ /dbt/profiles/
COPY models/ /dbt/models/

# Set environment variables
ENV DBT_PROFILES_DIR=/dbt/profiles

# Expose port for dbt docs
EXPOSE 8080

# Default command
CMD ["dbt", "run"]