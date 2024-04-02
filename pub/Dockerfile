FROM kixelated/moq-rs@sha256:f8abcef43f43b250b0c7e8bd64bb0bdc383e35749e342fcb477af6afb8cc6456

# Install required utilities and ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg wget

# Copy the publish script into the image
COPY ./publish /usr/local/bin/publish

# Use our publish script
CMD [ "publish" ]
