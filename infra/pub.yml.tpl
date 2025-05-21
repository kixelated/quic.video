#cloud-config

write_files:
  - path: /etc/systemd/system/hang-bbb.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run hang-bbb via docker
      Requires=docker.service
      After=docker.service

      [Service]
      ExecStart=docker run --rm \
        --name hang-bbb \
        --network="host" \
        --pull=always \
        --cap-add=SYS_PTRACE \
        -e RUST_LOG=debug -e RUST_BACKTRACE=1 \
        -e REGION=${region} \
        --entrypoint hang-bbb \
        ${docker}/hang \
        publish "https://relay.quic.video/demo/bbb.hang"

      ExecStop=docker stop hang-bbb

      # Take longer and longer to restart the process.
      Restart=always
      RestartSec=10s

  - path: /etc/systemd/system/moq-clock.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run moq-clock via docker
      Requires=docker.service
      After=docker.service

      [Service]
      ExecStart=docker run --rm \
        --name moq-clock \
        --network="host" \
        --pull=always \
        --cap-add=SYS_PTRACE \
        -e RUST_LOG=info -e RUST_BACKTRACE=1 \
        ${docker}/moq-clock --publish "https://relay.quic.video/clock"
      ExecStop=docker stop moq-clock

      # Take longer and longer to restart the process.
      Restart=always
      RestartSec=10s
      RestartSteps=6
      RestartMaxDelaySec=1m

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

  # Add Watchtower systemd service to restart containers on update
  - path: /etc/systemd/system/watchtower.service
    permissions: "0644"
    owner: root
    content: |
      [Unit]
      Description=Watchtower to auto-update containers
      After=docker.service
      Wants=docker.service

      [Service]
      Restart=on-failure
      RestartSec=10s
      ExecStart=docker run --rm \
        --name watchtower \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        containrrr/watchtower \
        --cleanup \
        --interval 300
      ExecStop=docker stop watchtower

runcmd:
  - systemctl daemon-reload
  - systemctl restart docker
  - systemctl start moq-bbb moq-clock
  - systemctl start watchtower
