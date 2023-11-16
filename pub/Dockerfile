FROM kixelated/moq-rs:latest

# Install required utilities and ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg wget

# Copy the publish script into the image
COPY ./publish /usr/local/bin/publish

# Use our publish script
CMD [ "publish" ]
