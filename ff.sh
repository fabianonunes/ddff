#!/usr/bin/env bash

DEST="rtmps://rtmp-api.facebook.com:443/rtmp/"
KEY=$1

bin/ffmpeg2 -i - \
  -hide_banner \
  -c:v copy \
  -c:a copy \
  -f flv "$DEST$KEY"
