import re
import time
import requests
import json
import os

# ==========================================
# CONFIGURATION
# ==========================================
# Path to the Linux SSH authentication log. 
# Note: You may need to run this script with sudo to read this file!
AUTH_LOG_FILE = '/var/log/auth.log'

# Where we will save the enriched data for our SIEM/Map to consume
OUTPUT_GEO_LOG = 'failed_logins_geo.json'

# Free IP Geolocation API (Rate limited, but great for student projects)
GEO_API_URL = "http://ip-api.com/json/{}"

# Cache to avoid spamming the API with the same IP over and over
known_ips = {}

def get_geolocation(ip_address):
    """Fetches location data for a given IP address."""
    if ip_address in known_ips:
        return known_ips[ip_address]
    
    try:
        response = requests.get(GEO_API_URL.format(ip_address))
        if response.status_code == 200:
            data = response.json()
            if data['status'] == 'success':
                geo_info = {
                    "ip": ip_address,
                    "country": data.get("country", "Unknown"),
                    "city": data.get("city", "Unknown"),
                    "latitude": data.get("lat", 0.0),
                    "longitude": data.get("lon", 0.0)
                }
                known_ips[ip_address] = geo_info
                return geo_info
    except Exception as e:
        print(f"[!] Error fetching geo data for {ip_address}: {e}")
    
    return None

def process_new_log_line(line):
    """Parses a log line, extracts IP, gets Geo data, and writes to output."""
    # Regex to find "Failed password" and extract the IP address
    # Example log: "Failed password for root from 192.168.1.100 port 22 ssh2"
    match = re.search(r"Failed password for .* from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)", line)
    
    if match:
        attacker_ip = match.group(1)
        print(f"[+] Attack detected from IP: {attacker_ip}")
        
        geo_data = get_geolocation(attacker_ip)
        
        if geo_data:
            print(f"    Location: {geo_data['city']}, {geo_data['country']}")
            # Append the JSON data to our output log file
            with open(OUTPUT_GEO_LOG, 'a') as f:
                json.dump(geo_data, f)
                f.write('\n')

def monitor_log_file(filepath):
    """Continuously monitors the log file for new lines (like 'tail -f')."""
    if not os.path.exists(filepath):
        print(f"[!] Log file {filepath} not found. Are you on Linux?")
        return

    print(f"[*] Monitoring {filepath} for failed SSH logins...")
    
    with open(filepath, 'r') as file:
        # Move to the end of the file
        file.seek(0, os.SEEK_END)
        
        while True:
            line = file.readline()
            if not line:
                time.sleep(1) # Wait for new logs to be written
                continue
            process_new_log_line(line)

if __name__ == "__main__":
    try:
        monitor_log_file(AUTH_LOG_FILE)
    except KeyboardInterrupt:
        print("\n[*] Honeypot monitoring stopped.")
    except PermissionError:
        print("\n[!] Permission Denied. Try running the script with 'sudo'.")