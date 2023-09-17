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

# Commands to be run during boot
runcmd:
  # Run the relay
  - docker run -d --name moq-relay \
    --network="host" -p 443:443/udp \
    --restart always \
    -v "/etc/cert:/etc/cert:ro"
    -e RUST_LOG=info \
    ${image}
    moq-relay --bind [::]:443 --cert "/etc/cert/crt.pem" --key "/etc/cert/key.pem"
