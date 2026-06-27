# SSH Honeypot Monitor

A Python-based security monitoring tool that tracks failed SSH login attempts and enriches them with geolocation data for SIEM integration and threat mapping.

## Features

- **Real-time SSH Log Monitoring**: Continuously monitors `/var/log/auth.log` for failed SSH authentication attempts
- **IP Geolocation Enrichment**: Automatically looks up attacker IP locations using the ip-api.com service
- **JSON Output**: Exports detected attacks with geolocation data to `failed_logins_geo.json` for integration with mapping/SIEM tools
- **IP Caching**: Reduces API calls by caching previously looked-up IP addresses

## Requirements

- Python 3.6+
- Linux system (for access to `/var/log/auth.log`)
- Internet connectivity (for geolocation API calls)
- sudo privileges (to read auth.log)

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/pavithraas111-debug/-.git
   cd -
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### Running Locally (Testing)

```bash
# Run with elevated privileges (required to read auth.log)
sudo python3 honeypot_monitor.py
```

### Running as a Service (Production)

#### Option 1: Systemd Service

1. **Create the systemd service file**:
   ```bash
   sudo nano /etc/systemd/system/honeypot-monitor.service
   ```

2. **Add the following configuration**:
   ```ini
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
   ```

3. **Install and start the service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable honeypot-monitor
   sudo systemctl start honeypot-monitor
   ```

4. **Check status**:
   ```bash
   sudo systemctl status honeypot-monitor
   sudo journalctl -u honeypot-monitor -f
   ```

#### Option 2: Cron Job (Run Periodically)

```bash
# Edit crontab
sudo crontab -e

# Add this line to run the monitor every hour
0 * * * * /usr/bin/python3 /opt/honeypot-monitor/honeypot_monitor.py >> /var/log/honeypot-monitor.log 2>&1
```

#### Option 3: Docker Deployment

Build and run in a containerized environment (see `Dockerfile` for details).

## Configuration

Edit the configuration variables at the top of `honeypot_monitor.py`:

```python
AUTH_LOG_FILE = '/var/log/auth.log'           # Path to SSH authentication log
OUTPUT_GEO_LOG = 'failed_logins_geo.json'     # Output file for detected attacks
GEO_API_URL = "http://ip-api.com/json/{}"     # Geolocation API endpoint
```

## Output Format

The script appends JSON entries to `failed_logins_geo.json`:

```json
{
  "ip": "192.168.1.100",
  "country": "United States",
  "city": "New York",
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

Each failed login attempt creates one JSON object per line (JSONL format).

## Integration with SIEM/Mapping Tools

The `failed_logins_geo.json` output can be ingested by:
- **Elasticsearch/Kibana**: Visualize attack patterns on geographic maps
- **Splunk**: Create dashboards for security analytics
- **GIS Software**: Plot attacks on world maps
- **Custom Web Dashboards**: Real-time threat visualization

## Logs

- **System logs**: `sudo journalctl -u honeypot-monitor -f`
- **Output data**: `failed_logins_geo.json`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Permission Denied** | Run with `sudo` or configure systemd to run as root |
| **Log file not found** | Ensure you're on a Linux system and SSH is configured |
| **No API responses** | Check internet connectivity; ip-api.com may be rate-limited |
| **Service won't start** | Check paths are correct and Python is installed at `/usr/bin/python3` |

## Security Considerations

⚠️ **Important**:
- This script requires root/sudo privileges to read SSH logs
- The geolocation API may be rate-limited; consider caching responses
- Output file (`failed_logins_geo.json`) may grow large; implement log rotation
- Consider using a private geolocation API for production deployments

## License

MIT

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.