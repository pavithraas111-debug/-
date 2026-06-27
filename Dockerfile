FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY requirements.txt .
COPY honeypot_monitor.py .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create output directory
RUN mkdir -p /var/log/honeypot-monitor

# Set environment variables
ENV OUTPUT_GEO_LOG=/var/log/honeypot-monitor/failed_logins_geo.json

# Run the honeypot monitor
CMD ["python3", "honeypot_monitor.py"]