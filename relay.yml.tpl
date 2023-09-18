#cloud-config

users:
  - name: moq
    uid: 2000

write_files:
  - path: /etc/cert/crt.pem
    content: |
      ${indent(6, crt)}
    permissions: "0600"
    owner: moq

  - path: /etc/cert/key.pem
    content: |
      ${indent(6, key)}
    permissions: "0600"
    owner: moq

  - path: /etc/systemd/system/moq-relay.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run moq-relay via docker

      [Service]
      ExecStart=/usr/bin/docker run --rm -u moq --name moq-relay --network="host" -v "/etc/cert:/etc/cert:ro" -e RUST_LOG=info ${image} moq-relay --bind [::]:443 --cert "/etc/cert/crt.pem" --key "/etc/cert/key.pem"
      ExecStop=/usr/bin/docker stop moq-relay
      ExecStopPost=/usr/bin/docker rm moq-relay

runcmd:
  - systemctl daemon-reload
  - systemctl start moq-relay.service
