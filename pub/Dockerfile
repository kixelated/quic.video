# draft-03
FROM kixelated/moq-rs@sha256:360d904e16935a884731acac4b1aa840504ad51250965e47b3892f4bbe27021b

# Install required utilities and ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg wget

# Copy the publish script into the image
COPY ./publish /usr/local/bin/publish

# Use our publish script
CMD [ "publish" ]
