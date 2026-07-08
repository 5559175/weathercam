#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
CAM_URL="http://camera.ip/cgi-bin/api.cgi?cmd=Snap&channel=0&rs=1&user=xxx&password=xxx&width=3840&height=2160"
REPO_DIR="/root/weathercam" 

# Set what you want displayed on GitHub here:
DISPLAY_NAME="Weather Cam Bot"
DISPLAY_EMAIL="weathercam@local.lan"
# ==========================================

# 1. Pull the crisp image straight into your folder
curl -s -o "$REPO_DIR/current.jpg" "$CAM_URL"

# 2. Grab the rapid broadcast from the WS2910 on port 8123 using a bidirectional pipe
# Create a temporary pipe file for the network handshake
rm -f /tmp/wpipe
mkfifo /tmp/wpipe

# Listen on port 8123, catch the data, and send the HTTP response back down the pipe
RAW_DATA=$(cat /tmp/wpipe | timeout 35 /usr/bin/nc -l -p 8123 2>/dev/null & echo "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" > /tmp/wpipe)

# Clean up the pipe file immediately
rm -f /tmp/wpipe

# Filter out the raw metrics
TEMPF=$(echo "$RAW_DATA" | grep -o 'tempf=[0-9.]*' | cut -d'=' -f2)
HUMIDITY=$(echo "$RAW_DATA" | grep -o 'humidity=[0-9]*' | cut -d'=' -f2)
WIND=$(echo "$RAW_DATA" | grep -o 'windspeedmph=[0-9.]*' | cut -d'=' -f2)

# Convert Fahrenheit to Celsius securely using awk math
if [ -n "$TEMPF" ]; then
    TEMPC=$(echo "$TEMPF" | awk '{print sprintf("%.1f", ($1 - 32) * 5 / 9)}')
    METRICS="Temp: ${TEMPC}°C | Humidity: ${HUMIDITY}% | Wind: ${WIND} mph"
else
    METRICS="Weather Data Syncing..."
fi

# 3. Write out the index.html template layout
cat << EOF > "$REPO_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <title>Live Weather Cam</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background-color: #0f172a;
            padding: 15px 10px;
            text-align: center;
            font-family: sans-serif;
        }
        img {
            max-width: 100%;
            max-height: calc(100vh - 80px);
            object-fit: contain;
            box-shadow: 0 4px 15px rgba(0,0,0,0.4);
        }
        .banner {
            margin-top: 15px;
            color: #cbd5e1;
            font-size: 1.2rem;
        }
    </style>
</head>
<body>
    <img src="current.jpg" alt="Live Weather Snapshot">
    <div class="banner">${METRICS}</div>
</body>
</html>
EOF

# 4. Native Git sync to the cloud with explicit identity overrides
cd "$REPO_DIR" || exit

# Inject the environment overrides so Git ignores the "root" system profile
export GIT_AUTHOR_NAME="$DISPLAY_NAME"
export GIT_AUTHOR_EMAIL="$DISPLAY_EMAIL"
export GIT_COMMITTER_NAME="$DISPLAY_NAME"
export GIT_COMMITTER_EMAIL="$DISPLAY_EMAIL"

# CRITICAL: Pull down any remote changes (like README edits) before trying to push
git pull --rebase origin main

git add current.jpg index.html
git commit -m "Update weather cam image and local weather metrics"

# Removed the silence flag temporarily so you can see errors if it fails manually
git push origin main
