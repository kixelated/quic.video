#cloud-config

write_files:
  - path: /etc/cert/crt.pem
    content: |
      ${indent(6, crt)}
    permissions: "0600"
    owner: root

  - path: /etc/cert/key.pem
    content: |
      ${indent(6, key)}
    permissions: "0600"
    owner: root

  - path: /etc/systemd/system/moq-relay.service
    permissions: "0644"
    owner: root
    content: |
      [Unit]
      Description=Run moq-relay via docker
      After=docker.service allow-quic.service
      Wants=docker.service allow-quic.service

      [Service]
      ExecStart=docker run --rm --name moq-relay --network="host" -v "/etc/cert:/etc/cert:ro" -e RUST_LOG=info -e RUST_BACKTRACE=1 ${image} moq-relay --bind 0.0.0.0:443 --cert "/etc/cert/crt.pem" --key "/etc/cert/key.pem"
      ExecStop=docker stop moq-relay

  - path: /etc/systemd/system/allow-quic.service
    permissions: "0644"
    owner: root
    content: |
      [Unit]
      Description=Allow QUIC traffic through the host firewall

      [Service]
      Type=oneshot
      RemainAfterExit=true
      ExecStart=iptables -A INPUT -p udp --dport 443 -j ACCEPT

runcmd:
  - systemctl daemon-reload
  - systemctl start moq-relay
