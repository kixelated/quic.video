#cloud-config

write_files:
  - path: /etc/systemd/system/moq-pub.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run moq-pub via docker
      Requires=docker.service
      After=docker.service

      [Service]
      ExecStart=docker run --rm \
        --name moq-karp \
        --network="host" \
        --pull=always \
        --cap-add=SYS_PTRACE \
        -e RUST_LOG=debug -e RUST_BACKTRACE=1 \
        -e REGION=${region} \
        ${image}
      ExecStop=docker stop moq-pub

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
        ${image} moq-clock --publish "https://relay.quic.video/clock"
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
      MaxFileSec=1day
      MaxRetentionSec=1week

runcmd:
  - systemctl daemon-reload
  - systemctl restart docker
  - systemctl start moq-pub moq-clock
