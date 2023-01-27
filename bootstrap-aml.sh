#/bin/bash
set -e

echo "ec2-user  ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers
sudo mkdir -p /ect/containerd
sudo tee --append /etc/containerd/config.toml <<EOF
[proxy_plugins]
  [proxy_plugins.squashoverlay]
    type = "snapshot"
    address = "/var/run/containerd/squashoverlay/plugin.sock"
EOF

sudo systemctl restart containerd


sudo mkdir -p /app/go/infra/anyscaled/anyscaled_
sudo curl -fsSL \
	https://github.com/hckuo-anyscale/faststartup_bootstrap/raw/main/anyscaled_shim \
	-o /app/go/infra/anyscaled/anyscaled_/anyscaled_shim
sudo chmod a+x /app/go/infra/anyscaled/anyscaled_/anyscaled_shim

sudo tee /lib/systemd/system/anyscaled.service <<EOF
[Unit]
Description=Anyscale Daemon Process
[Service]
Restart=always
RestartSec=5
WorkingDirectory=/app
ExecStart=/app/go/infra/anyscaled/anyscaled_/anyscaled_shim
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl restart anyscaled
