#!/bin/bash
set -euo pipefail

ADDR=${ADDR:-"https://relay.quic.video"}
NAME=${NAME:-"bbb"}
URL=${URL:-"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"}

# Download the funny bunny
wget "${URL}" -O "${NAME}.mp4"

# ffmpeg
#   -hide_banner: Hide the banner
#   -v quiet: and any other output
#   -stats: But we still want some stats on stderr
#   -stream_loop -1: Loop the broadcast an infinite number of times
#   -re: Output in real-time
#   -i "${INPUT}": Read from a file on disk
#   -vf "drawtext": Render the current minute:second in the corner of the video
#   -an: Disable audio for now
#   -f mp4: Output to mp4 format
#   -movflags: Build a fMP4 file with a frame per fragment
# - | moq-pub: Output to stdout and moq-pub to publish

# Run ffmpeg
ffmpeg \
	-hide_banner \
	-v quiet \
	-stats \
	-stream_loop -1 \
	-re \
    -i "${NAME}.mp4" \
	-vf "drawtext=text='%{localtime\: %M\\\\\:%S}':x=24:y=24:fontsize=64:fontcolor=white:box=1:boxcolor=black@0.5" \
	-an \
    -f mp4 \
	-movflags empty_moov+frag_every_frame+separate_moof+omit_tfhd_offset \
	- | moq-pub "${ADDR}/${NAME}"
