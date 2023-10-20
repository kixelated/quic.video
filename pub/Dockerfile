# Start with the moq-rs base image
FROM kixelated/moq-rs

# Install required utilities and ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg wget

# Copy the publish script into the image
COPY publish.sh /usr/local/bin/publish

# Default to publishing BBB
CMD [ "publish" ]
