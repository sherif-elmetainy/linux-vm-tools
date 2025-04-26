# Hyper-V integration services
apt install -y linux-tools-virtual-hwe-24.04 linux-cloud-tools-virtual-hwe-24.04
# Fix-up journal log error
mkdir /usr/libexec/hypervkvpd/
ln -s /usr/sbin/hv_get_dhcp_info /usr/libexec/hypervkvpd/hv_get_dhcp_info
ln -s /usr/sbin/hv_get_dns_info /usr/libexec/hypervkvpd/hv_get_dns_info

# Install xrdp
apt install -y xrdp
cp -p /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.original
cp -p /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.original

# Allow enhanced session
sed -i -e 's/^port=3389$/port=3389 vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini

# Rename redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini


# Use "Ubuntu" session
cat > /etc/xrdp/startubuntu.sh << EOF
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/startubuntu.sh
# use the script to setup the ubuntu session
sed -i -e 's/startwm/startubuntu/g' /etc/xrdp/sesman.ini

# Fixes login black screen delay
echo "blacklist vmw_vsock_vmci_transport" > /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf

# Unlock keyring on login
cat > /etc/pam.d/xrdp-sesman <<'EOT'
#%PAM-1.0
auth     required  pam_env.so readenv=1
auth     required  pam_env.so readenv=1 envfile=/etc/default/locale
@include common-auth
-auth    optional  pam_gnome_keyring.so
-auth    optional  pam_kwallet5.so

@include common-account

@include common-password

# Ensure resource limits are applied
session    required     pam_limits.so
# Set the loginuid process attribute.
session    required     pam_loginuid.so
# Update wtmp/lastlog
session    optional     pam_lastlog.so quiet
@include common-session
-session optional  pam_gnome_keyring.so auto_start
-session optional  pam_kwallet5.so auto_start
EOT


cp -p /etc/default/grub /etc/default/grub.default
# Show boot log instead of splash screen
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/g' /etc/default/grub
# Faster boot - reduce grub wait for input timeout
echo 'GRUB_RECORDFAIL_TIMEOUT=3' >> /etc/default/grub
update-grub