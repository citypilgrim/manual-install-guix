#!/bin/bash
# run as root

# working in
cd /tmp

# downloading binary and signature
wget https://ftp.gnu.org/gnu/guix/guix-binary-1.4.0.x86_64-linux.tar.xz
wget https://ftp.gnu.org/gnu/guix/guix-binary-1.4.0.x86_64-linux.tar.xz.sig

# verifying
wget 'https://sv.gnu.org/people/viewgpg.php?user_id=15145' \
     -qO - | gpg --import -
gpg --verify guix-binary-1.4.0.x86_64-linux.tar.xz

# installing
tar --warning=no-timestamp -xf \
    guix-binary-1.4.0.x86_64-linux.tar.xz
mv var/guix /var/ && mv gnu /
rm -rf var gnu
chmod 777 /tmp       # unzipping binary resulted in permissions change

# installing guix profile
mkdir -p ~root/.config/guix
ln -sf /var/guix/profiles/per-user/root/current-guix \
   ~root/.config/guix/current
. /root/.config/guix/current/etc/profile

# creating build users
groupadd --system guixbuild
for i in $(seq -w 1 10);
do
    useradd -g guixbuild -G guixbuild,kvm       \
            -d /var/empty -s $(which nologin)   \
            -c "Guix build user $i" --system    \
            guixbuilder$i;
done

# making guix available to all users
mkdir -p /usr/local/bin
cd /usr/local/bin
ln -s /var/guix/profiles/per-user/root/current-guix/bin/guix
mkdir -p /usr/local/share/info
cd /usr/local/share/info
for i in /var/guix/profiles/per-user/root/current-guix/share/info/* ;
do ln -s $i ; done

# authorising substitute repositories
guix archive --authorize < \
     ~root/.config/guix/current/share/guix/ci.guix.gnu.org.pub
guix archive --authorize < \
     ~root/.config/guix/current/share/guix/bordeaux.guix.gnu.org.pub

# adding guix daemon to the service

## systemd
cp ~root/.config/guix/current/lib/systemd/system/gnu-store.mount \
   ~root/.config/guix/current/lib/systemd/system/guix-daemon.service \
   /etc/systemd/system/
systemctl enable --now gnu-store.mount guix-daemon

# ## Upstart
# initctl reload-configuration
# cp ~root/.config/guix/current/lib/upstart/system/guix-daemon.conf \
#    /etc/init/
# start guix-daemon

# ## run manually
# ~root/.config/guix/current/bin/guix-daemon \
#     --build-users-group=guixbuild
