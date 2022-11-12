#!/bin/bash
# Purpose: Set Docker Socket Permissions after reboot & Docker Logging

###########################
# Docker Socket Permissions
###########################
cat <<EOF > ${HOME}/docker-socket.sh
#!/bin/bash
chmod 666 /var/run/docker.sock
#End
EOF

chmod +x ${HOME}/docker-socket.sh

cat <<EOF > /etc/systemd/system/docker-socket.service
[Unit]
Description=Docker Socket Permissions
After=docker.service
BindsTo=docker.service
ReloadPropagatedFrom=docker.service

[Service]
Type=oneshot
ExecStart=${HOME}/docker-socket.sh
ExecReload=${HOME}/docker-socket.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl start docker-socket.service

systemctl enable docker-socket.service

################
# Docker Logging
################

cat << EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "1024m",
    "max-file": "5"
  }
}

EOF

shutdown -r now

# End
