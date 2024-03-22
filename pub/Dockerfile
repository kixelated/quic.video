# draft-03
FROM kixelated/moq-rs@sha256:3471125473fd6df084c47e8e6d19b1a5e3c709f3818a830b5d946cd244b7209e

# Install required utilities and ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg wget

# Copy the publish script into the image
COPY ./publish /usr/local/bin/publish

# Use our publish script
CMD [ "publish" ]
