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

# 1. First, make sure the repository folder is clean and perfectly synced with GitHub
cd "$REPO_DIR" || exit
git reset --hard HEAD >/dev/null 2>&1
git pull --rebase origin main

# 2. Pull the crisp image straight into a TEMPORARY file outside of the repo
curl -s -o /tmp/raw_snap.jpg "$CAM_URL"

# 3. Grab the rapid broadcast from the WS2910 on port 8123 using a bidirectional pipe
rm -f /tmp/wpipe
mkfifo /tmp/wpipe
RAW_DATA=$(cat /tmp/wpipe | timeout 35 /usr/bin/nc -l -p 8123 2>/dev/null & echo "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" > /tmp/wpipe)
rm -f /tmp/wpipe

# Filter out the raw metrics
TEMPF=$(echo "$RAW_DATA" | grep -o 'tempf=[0-9.]*' | cut -d'=' -f2)
HUMIDITY=$(echo "$RAW_DATA" | grep -o 'humidity=[0-9]*' | cut -d'=' -f2)
WIND=$(echo "$RAW_DATA" | grep -o 'windspeedmph=[0-9.]*' | cut -d'=' -f2)

# Convert Fahrenheit to Celsius securely using awk math
if [ -n "$TEMPF" ]; then
    TEMPC=$(echo "$TEMPF" | awk '{print sprintf("%.1f", ($1 - 32) * 5 / 9)}')
    METRICS="Temp: ${TEMPC}°C  |  Humidity: ${HUMIDITY}%  |  Wind: ${WIND} mph"
else
    METRICS="Weather Data Syncing..."
fi

# 4. Superimpose text onto the top of the image (-gravity North)
if [ -f /tmp/raw_snap.jpg ]; then
    convert /tmp/raw_snap.jpg \
      -font "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" -pointsize 48 \
      -gravity North \
      -stroke "#000000" -strokewidth 3 -annotate +0+20 "$METRICS" \
      -stroke none      -fill "#ffffff" -annotate +0+20 "$METRICS" \
      "$REPO_DIR/current.jpg"

    # Clean up the temp file
    rm -f /tmp/raw_snap.jpg
fi

# 5. Write out the index.html template layout using the identical $METRICS string
cat << EOF > "$REPO_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <title>Live Weather Cam</title>
    
    <meta http-equiv="cache-control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="pragma" content="no-cache">
    <meta http-equiv="expires" content="0">

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
            font-size: 1.1rem;
        }
    </style>
</head>
<body>
    <img id="weathercam" alt="Live Weather Snapshot">
    <div class="banner">${METRICS}</div>

    <script>
        // Shatter mobile cache engines by appending a live unique runtime timestamp 
        document.getElementById('weathercam').src = 'current.jpg?t=' + new Date().getTime();
    </script>
</body>
</html>
EOF

# 6. Push our newly overwritten, crisp files safely to the cloud
export GIT_AUTHOR_NAME="$DISPLAY_NAME"
export GIT_AUTHOR_EMAIL="$DISPLAY_EMAIL"
export GIT_COMMITTER_NAME="$DISPLAY_NAME"
export GIT_COMMITTER_EMAIL="$DISPLAY_EMAIL"

git add current.jpg index.html
git commit -m "Update weather cam image with synchronized dual-layer weather metrics"
git push origin main > /dev/null 2>&1
