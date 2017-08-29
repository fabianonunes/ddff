#!/usr/bin/env bash

SRC=$(youtube-dl -f 93 -g "https://www.youtube.com/watch?v=$2")
DEST="rtmps://rtmp-api.facebook.com:443/rtmp/"
KEY=$1

ffmpeg -i "$SRC" \
  -deinterlace \
  -c:v libx264 -pix_fmt yuv420p -r 30 -g 60 -preset veryfast \
  -c:a aac -ar 44100 -q:a 3 -b:a 128k \
  -maxrate 1024k -threads 0 -bufsize 1000k \
  -f flv "$DEST$KEY"
