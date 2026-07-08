#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
CAM_URL="http://camera.ip/cgi-bin/api.cgi?cmd=Snap&channel=0&rs=1&user=xxx&password=xxx&width=3840&height=2160"
REPO_DIR="/root/weathercam" # Ensure this points to the absolute path of your repo

# Set what you want displayed on GitHub here:
DISPLAY_NAME="Weather Cam Bot"
DISPLAY_EMAIL="weathercam@local.lan"
# ==========================================

# 1. Pull the crisp image straight into your folder
curl -s -o "$REPO_DIR/current.jpg" "$CAM_URL"

# 2. Native Git sync to the cloud with explicit identity overrides
cd "$REPO_DIR" || exit

# Inject the environment overrides so Git ignores the "root" system profile
export GIT_AUTHOR_NAME="$DISPLAY_NAME"
export GIT_AUTHOR_EMAIL="$DISPLAY_EMAIL"
export GIT_COMMITTER_NAME="$DISPLAY_NAME"
export GIT_COMMITTER_EMAIL="$DISPLAY_EMAIL"

git add current.jpg
git commit -m "Update weather cam"
git push origin main > /dev/null 2>&1
