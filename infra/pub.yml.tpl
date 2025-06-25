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
        ${docker_image} \
        publish "https://relay.quic.video/${demo_token}.jwt"

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
  - systemctl start hang-bbb
