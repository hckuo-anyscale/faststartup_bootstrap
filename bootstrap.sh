#/bin/bash
set -e

install_containerd() {
	VERSION=1.7.0-beta.2
	CONTAINERD_TAR=containerd-$VERSION-linux-amd64.tar.gz
	curl -fsSL https://github.com/containerd/containerd/releases/download/v$VERSION/$CONTAINERD_TAR -o /tmp/$CONTAINERD_TAR
	sudo tar Cxzvf /usr/local /tmp/$CONTAINERD_TAR
	sudo mkdir -p /usr/local/lib/systemd/system

	sudo tee /usr/local/lib/systemd/system/containerd.service <<EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target
[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999
[Install]
WantedBy=multi-user.target
EOF

	sudo mkdir -p /etc/containerd
	sudo tee --append /etc/containerd/config.toml <<EOF
[proxy_plugins]
  [proxy_plugins.squashoverlay] type = "snapshot"
    address = "/var/run/containerd/squashoverlay/plugin.sock"
EOF


	# install runc
	curl -fsSL https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 -o /tmp/runc.amd64
	sudo install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc
	sudo systemctl restart containerd
}

install_anyscaled() {
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
}

echo "ubuntu  ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers

install_anyscaled &
install_containerd &
wait
