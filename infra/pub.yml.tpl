#cloud-config

write_files:
  - path: /etc/systemd/system/moq-source.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Produce a stream of fMP4 segments from a source video
      Requires=docker.service moq-pipe.socket
      After=docker.service moq-pipe.socket
      PartOf=moq-pub.service

      [Service]
      Sockets=moq-pipe.socket
      StandardOutput=fd:moq-pipe.socket

      ExecStart=docker run --rm --name moq-source -v /var/moq:/var/moq jrottenberg/ffmpeg -hide_banner -v quiet -stream_loop -1 -re -i /var/moq/source.mp4 -an -f mp4 -movflags empty_moov+frag_every_frame+separate_moof+omit_tfhd_offset -
      ExecStop=docker stop moq-source
      Restart=always

  - path: /etc/systemd/system/moq-pipe.socket
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Pipe media to moq-pub
      PartOf=moq-pub.service

      [Socket]
      ListenFIFO=/run/moq-pipe
      RemoveOnStop=yes

  - path: /etc/systemd/system/moq-pub.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Run moq-pub via docker
      Requires=docker.service moq-pipe.socket
      After=docker.service moq-pipe.socket
      BindsTo=moq-source.service

      [Service]
      Sockets=moq-pipe.socket
      StandardInput=fd:moq-pipe.socket

      ExecStart=docker run --rm --name moq-pub --network="host" -e RUST_LOG=info -e RUST_BACKTRACE=1 ${image} moq-pub "moq://${addr}/BigBuckBunny"
      ExecStop=docker stop moq-pub
      Restart=always

runcmd:
  - wget http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4 -O /var/moq/source.mp4
  - systemctl daemon-reload
  - systemctl start moq-pub
