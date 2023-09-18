#cloud-config

users:
  - name: moq
    uid: 2000

write_files:
  - path: /etc/systemd/system/moq-source.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Produce a stream of fMP4 segments from a source video

      [Service]
      Sockets=moq-pub.socket
      StandardOutput=fd:moq-pub.socket

      ExecStart=docker run --rm -u moq --name moq-source -v /var/moq:/var/moq jrottenberg/ffmpeg -hide_banner -v quiet -stream_loop -1 -re -i /var/moq/source.mp4 -an -f mp4 -movflags empty_moov+frag_every_frame+separate_moof+omit_tfhd_offset -
      ExecStop=docker stop moq-source
      ExecStopPost=docker rm moq-source

  - path: /etc/systemd/system/moq-pub.socket
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Accept connections to moq-pub

      [Socket]
      ListenFIFO=/run/moq-pub
      Accept=true

  - path: /etc/systemd/system/moq-pub.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run moq-pub via docker

      [Service]
      Sockets=moq-pub.socket
      StandardInput=fd:moq-pub.socket

      ExecStart=docker run --rm -u moq --name moq-pub --network="host" -e RUST_LOG=info ${image} moq-pub "moq://${addr}/BigBuckBunny"
      ExecStop=docker stop moq-pub
      ExecStopPost=docker rm moq-pub

runcmd:
  - wget http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4 -O /var/moq/source.mp4
  - systemctl daemon-reload
  - systemctl start moq-source
  - systemctl start moq-pub
