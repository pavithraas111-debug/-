# Deployment Guide

This guide covers various deployment methods for the SSH Honeypot Monitor.

## Quick Start (Automated)

The easiest way to deploy on Linux:

```bash
git clone https://github.com/pavithraas111-debug/-.git
cd -
sudo bash deploy.sh
```

This will:
- Install all dependencies
- Copy files to `/opt/honeypot-monitor`
- Create a systemd service
- Start the service automatically

## Manual Deployment (Systemd)

### 1. Prepare the Environment

```bash
# Clone repository
git clone https://github.com/pavithraas111-debug/-.git
cd -

# Install Python and pip
sudo apt-get update
sudo apt-get install -y python3 python3-pip

# Install dependencies
pip3 install -r requirements.txt
```

### 2. Create Installation Directory

```bash
sudo mkdir -p /opt/honeypot-monitor
sudo cp honeypot_monitor.py /opt/honeypot-monitor/
sudo cp requirements.txt /opt/honeypot-monitor/
```

### 3. Create Systemd Service

```bash
sudo tee /etc/systemd/system/honeypot-monitor.service > /dev/null << EOF
[Unit]
Description=SSH Honeypot Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/honeypot-monitor
ExecStart=/usr/bin/python3 /opt/honeypot-monitor/honeypot_monitor.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

### 4. Enable and Start

```bash
sudo systemctl daemon-reload
sudo systemctl enable honeypot-monitor
sudo systemctl start honeypot-monitor

# Verify
sudo systemctl status honeypot-monitor
```

## Docker Deployment

### Using Docker Compose (Recommended)

```bash
# Clone and navigate
git clone https://github.com/pavithraas111-debug/-.git
cd -

# Build and start
sudo docker-compose up -d

# View logs
sudo docker-compose logs -f

# Stop
sudo docker-compose down
```

### Using Docker directly

```bash
# Build image
docker build -t ssh-honeypot-monitor .

# Run container
docker run -d \
  --name honeypot-monitor \
  --restart always \
  -v /var/log/auth.log:/var/log/auth.log:ro \
  ssh-honeypot-monitor

# View logs
docker logs -f honeypot-monitor
```

## Kubernetes Deployment

### Using Helm Chart

```yaml
# values.yaml
image:
  repository: ssh-honeypot-monitor
  tag: latest

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 250m
    memory: 128Mi

persistence:
  enabled: true
  size: 10Gi
```

### Manual Kubernetes Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: honeypot-monitor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: honeypot-monitor
  template:
    metadata:
      labels:
        app: honeypot-monitor
    spec:
      containers:
      - name: honeypot-monitor
        image: ssh-honeypot-monitor:latest
        volumeMounts:
        - name: auth-log
          mountPath: /var/log/auth.log
          readOnly: true
        - name: output
          mountPath: /var/log/honeypot-monitor
      volumes:
      - name: auth-log
        hostPath:
          path: /var/log/auth.log
      - name: output
        emptyDir: {}
```

## Cloud Deployment

### AWS EC2

```bash
# 1. Launch Ubuntu EC2 instance
# 2. SSH into instance
ssh -i your-key.pem ubuntu@your-instance

# 3. Run setup
sudo bash
git clone https://github.com/pavithraas111-debug/-.git
cd -
bash deploy.sh
```

### DigitalOcean Droplet

```bash
# Create Droplet with Ubuntu 22.04

# SSH in and run:
curl -fsSL https://raw.githubusercontent.com/pavithraas111-debug/-/main/deploy.sh | sudo bash
```

### Azure Container Instances

```bash
az container create \
  --resource-group myResourceGroup \
  --name honeypot-monitor \
  --image ssh-honeypot-monitor:latest \
  --restart-policy Always
```

## Monitoring & Maintenance

### Check Service Status

```bash
# Check if running
sudo systemctl status honeypot-monitor

# View real-time logs
sudo journalctl -u honeypot-monitor -f

# View last 50 lines
sudo journalctl -u honeypot-monitor -n 50

# View logs from specific date
sudo journalctl -u honeypot-monitor --since "2024-01-15"
```

### Output File Management

```bash
# Check output size
ls -lh failed_logins_geo.json

# Rotate logs (archive old data)
gzip failed_logins_geo.json
mv failed_logins_geo.json.gz failed_logins_geo.$(date +%Y%m%d).json.gz
```

### Log Rotation (Recommended)

Create `/etc/logrotate.d/honeypot-monitor`:

```
/opt/honeypot-monitor/failed_logins_geo.json {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied reading auth.log | Ensure service runs as root |
| Service won't start | Check `/etc/systemd/system/honeypot-monitor.service` permissions |
| API rate limit reached | Add delay between requests or use cached results |
| Low disk space | Implement log rotation (see above) |
| High memory usage | Increase API response caching or restart periodically |

## Uninstallation

### Systemd Service

```bash
sudo systemctl stop honeypot-monitor
sudo systemctl disable honeypot-monitor
sudo rm /etc/systemd/system/honeypot-monitor.service
sudo rm -rf /opt/honeypot-monitor
sudo systemctl daemon-reload
```

### Docker

```bash
docker-compose down
docker rmi ssh-honeypot-monitor
```

## Performance Tuning

### Increase API Caching

Modify `honeypot_monitor.py` to increase the cache:

```python
# Before: known_ips = {}
# After: Persist cache to disk
import pickle

def save_cache():
    with open('ip_cache.pkl', 'wb') as f:
        pickle.dump(known_ips, f)

def load_cache():
    try:
        with open('ip_cache.pkl', 'rb') as f:
            return pickle.load(f)
    except:
        return {}
```

### Reduce Memory Usage

```bash
# Use memory-efficient Python
python3 -OO honeypot_monitor.py

# Or limit process memory
systemctl set-property honeypot-monitor MemoryLimit=128M
```

## Support

For issues or questions, please open a GitHub issue or contact the maintainers.