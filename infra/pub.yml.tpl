#cloud-config

write_files:
  - path: /etc/systemd/system/hang-bbb-prepare.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Prepare video for hang-bbb
      Requires=docker.service
      After=docker.service
      Before=hang-bbb.service

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      WorkingDirectory=/tmp
      ExecStart=/bin/bash -c '\
        # Download the video \
        docker run --rm -v /tmp:/tmp alpine:latest \
          wget -nv "$${URL:-http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4}" \
          -O /tmp/tmp.mp4 && \
        # Fragment the video \
        docker run --rm -v /tmp:/tmp linuxserver/ffmpeg:latest \
          -y -loglevel error -i /tmp/tmp.mp4 \
          -c copy \
          -f mp4 -movflags cmaf+separate_moof+delay_moov+skip_trailer+frag_every_frame \
          /tmp/fragmented.mp4 && \
        rm -f /tmp/tmp.mp4'

  - path: /etc/systemd/system/hang-bbb.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run hang-bbb via docker
      Requires=docker.service hang-bbb-prepare.service
      After=docker.service hang-bbb-prepare.service

      [Service]
      ExecStart=/bin/bash -c '\
        docker run --rm -v /tmp:/tmp:ro linuxserver/ffmpeg:latest \
          -stream_loop -1 \
          -hide_banner \
          -v quiet \
          -re \
          -i /tmp/fragmented.mp4 \
          -c copy \
          -f mp4 \
          -movflags cmaf+separate_moof+delay_moov+skip_trailer+frag_every_frame \
          - | \
        docker run --rm -i \
          --name hang-bbb \
          --network="host" \
          --pull=always \
          --cap-add=SYS_PTRACE \
          -e RUST_LOG=debug -e RUST_BACKTRACE=1 \
          ${docker_image} \
          publish --url https://relay.moq.dev/demo?jwt=${demo_token} --name bbb'

      ExecStop=docker stop hang-bbb

      # Take longer and longer to restart the process.
      Restart=always
      RestartSec=10s

  - path: /etc/docker/daemon.json
    content: |
      { "mtu": 1460 }

  - path: /etc/systemd/journald.conf
    content: |
      [Journal]
      SystemMaxUse=500M
      SystemKeepFree=1G
      MaxFileSec=1hour
      MaxRetentionSec=1day

  # Delete docker images and containers that are no longer in use
  - path: /etc/cron.weekly/docker-cleanup
    permissions: "0755"
    owner: root
    content: |
      #!/bin/sh
      docker system prune -af

runcmd:
  - systemctl daemon-reload
  - systemctl restart docker
  - systemctl start hang-bbb-prepare
  - systemctl start hang-bbb
