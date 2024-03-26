#cloud-config

write_files:
  # Write the certificate to disk
  - path: /etc/cert/${public_host}.crt
    content: |
      ${indent(6, public_cert)}
    permissions: "0644"
    owner: root

  # Write the private key to disk
  - path: /etc/cert/${public_host}.key
    content: |
      ${indent(6, public_key)}
    permissions: "0600"
    owner: root

  # Write the internal certificate to disk
  - path: /etc/cert/${internal_host}.crt
    content: |
      ${indent(6, internal_cert)}
    permissions: "0644"
    owner: root

  # Write the internal private key to disk
  - path: /etc/cert/${internal_host}.key
    content: |
      ${indent(6, internal_key)}
    permissions: "0600"
    owner: root

  # Write our internal CA to disk
  # Unfortuantely, cos-cloud doesn't seem to support the ca_certs module
  - path: /etc/cert/internal.ca
    content: |
      ${indent(6, internal_ca)}
    permissions: "0644"
    owner: root

  # Create a systemd service to run the docker image
  - path: /etc/systemd/system/moq-relay.service
    permissions: "0644"
    owner: root
    content: |
      [Unit]
      Description=Run moq-relay via docker
      After=docker.service allow-quic.service
      Wants=docker.service allow-quic.service

      [Service]
      Restart=on-failure
      RestartSec=5s
      ExecStart=docker run --rm \
        --name moq-relay \
        --network="host" \
        --pull=always \
        --cap-add=SYS_PTRACE \
        -v "/etc/cert:/etc/cert:ro" \
        -e RUST_LOG=debug -e RUST_BACKTRACE=1 \
        ${image} moq-relay --listen 0.0.0.0:443 \
        --tls-cert "/etc/cert/${internal_host}.crt" --tls-key "/etc/cert/${internal_host}.key" \
        --tls-cert "/etc/cert/${public_host}.crt" --tls-key "/etc/cert/${public_host}.key" \
        --tls-root "/etc/cert/internal.ca" \
        --api "${api_url}" --api-node "https://${internal_host}"
      ExecStop=docker stop moq-relay

  # GCP configures a firewall by default that blocks all UDP traffic
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

  # There's a mismatch between the GCP network MTU and the docker MTU
  - path: /etc/docker/daemon.json
    content: |
      { "mtu": 1460 }

  # Clear out the logs after a week
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
  - systemctl start moq-relay
