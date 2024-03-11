# draft-03
FROM kixelated/moq-rs@sha256:82720ba9e5c384f69f5749d65814ae108e6bb3d6fbf3305c8c9dbb36738a8f6f

# Install required utilities and ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg wget

# Copy the publish script into the image
COPY ./publish /usr/local/bin/publish

# Use our publish script
CMD [ "publish" ]
