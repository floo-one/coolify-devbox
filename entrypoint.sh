#!/bin/bash
set -e

# Persist SSH host keys on the volume so they survive image redeploys.
# Host keys normally live in the image's /etc/ssh and are regenerated on every
# rebuild, which makes clients see a "REMOTE HOST IDENTIFICATION HAS CHANGED"
# warning after each redeploy. Keeping them on the mounted volume keeps the
# server identity stable across redeploys (it still changes on a node swap).
HOSTKEY_DIR=/home/dev/.ssh_host_keys
mkdir -p "$HOSTKEY_DIR"
[ -f "$HOSTKEY_DIR/ssh_host_ed25519_key" ] || ssh-keygen -t ed25519 -f "$HOSTKEY_DIR/ssh_host_ed25519_key" -N "" -q
[ -f "$HOSTKEY_DIR/ssh_host_rsa_key" ]     || ssh-keygen -t rsa -b 4096 -f "$HOSTKEY_DIR/ssh_host_rsa_key" -N "" -q
chmod 600 "$HOSTKEY_DIR"/*_key
chmod 644 "$HOSTKEY_DIR"/*_key.pub

# Refresh authorized_keys from env on every start (rotate via Coolify env + restart)
mkdir -p /home/dev/.ssh
echo "$AUTHORIZED_KEYS" > /home/dev/.ssh/authorized_keys
chown -R dev:dev /home/dev/.ssh
chmod 700 /home/dev/.ssh
chmod 600 /home/dev/.ssh/authorized_keys

# Ensure the volume-mounted home has correct ownership (first boot)
chown dev:dev /home/dev

exec /usr/sbin/sshd -D -e \
  -h "$HOSTKEY_DIR/ssh_host_ed25519_key" \
  -h "$HOSTKEY_DIR/ssh_host_rsa_key"
