# Weathercam

Gemini-coded script and index.html which:

- Captures a still 4K image from a Reolink CX810 IP security camera
- Embeds the weather metrics collected by an Ecowitt WS69 array and WS2910 station (configured via a "custom" upload with server listening on TCP/8123). Image is ready to serve on various public webcam sites.
- Also displays the same metrics in HTML under the image for ease of reading on mobile devices.
- Auto-pushes to GitHub (to serve via Pages to permit easy sharing elsewhere).

Requires imagemagick, fonts-liberation, netcat, curl and git.

Script can be run on a cron schedule to update the image and weather data periodically.
