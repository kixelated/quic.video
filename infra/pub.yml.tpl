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
      ExecStartPre=docker pull ${image}
      ExecStart=docker run --rm --name moq-pub --network="host" \
        -e RUST_LOG=info -e RUST_BACKTRACE=1 \
        ${image}
      ExecStop=docker stop moq-pub

      # Take longer and longer to restart the process.
      Restart=always
      RestartSec=10s
      RestartSteps=6
      RestartMaxDelaySec=1m

  - path: /etc/docker/daemon.json
    content: |
      { "mtu": 1460 }

runcmd:
  - systemctl daemon-reload
  - systemctl restart docker
  - systemctl start moq-pub
