# Weathercam

Gemini-coded script and index.html which captures a still 4K image from a Reolink CX810 IP security camera, and push to GitHub (to serve via Pages to permit easy sharing elsewhere).

It additionally displays the temperature, humidity and wind speed data collected by an Ecowitt WS69 array and WS2910 station (configured via the "custom" upload with server listening on TCP/8123).

Script can be run on a cron schedule to update the image and weather data periodically.
