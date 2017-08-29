#!/usr/bin/env bash

bin/ffmpeg2 -i - \
  -hide_banner \
  -deinterlace \
  -strict -2 \
  -c:v libx264 -pix_fmt yuv420p -r 30 -g 60 -preset veryfast \
  -c:a aac -ar 44100 -q:a 3 -b:a 128k \
  -maxrate 1024k -threads 0 -bufsize 1000k \
  -f flv -
