DEST="rtmps://rtmp-api.facebook.com:443/rtmp/"
KEY=$1

dd if=/dev/dvb/adapter0/dvr0 conv=noerror | \
./bin/ffmpeg2 -i - \
  -hide_banner \
  -deinterlace \
  -strict -2 \
  -c:v libx264 -pix_fmt yuv420p -r 30 -g 60 -preset veryfast \
  -c:a aac -ar 44100 -q:a 3 -b:a 128k \
  -maxrate 1024k -threads 0 -bufsize 1000k \
  -f flv $DEST$KEY
