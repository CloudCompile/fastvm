#!/bin/bash
set -euo pipefail
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y default-jre
wget -qO /opt/TLauncher.jar https://dl2.tlauncher.org/file/tlauncher/files/TLauncher-2.895.jar
cat > /usr/local/bin/tlauncher << 'EOF'
#!/bin/bash
java -jar /opt/TLauncher.jar "$@"
EOF
chmod +x /usr/local/bin/tlauncher
rm -rf /var/lib/apt/lists/*
