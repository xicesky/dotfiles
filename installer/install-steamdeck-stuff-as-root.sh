#!/bin/sh

# Note: etckeeper seems to mess it up, it won't boot anymore

#pacman -S etckeeper
#git config --global user.name "Markus Dangl"
#git config --global user.email "markus@q1cc.net"
#git config --global init.defaultBranch main
#git config --global alias.st status
#etckeeper init
#etckeeper commit

# Already installed on steam deck:
#   vim htop iotop p7zip curl wget tmux
#   gzip bzip2 strace lzma zsh
# Not found in pacman...?
#   bc
# Replacments
#   dig -> dog (because we don't want to install the compete "bind" package)

# Enable SSH
echo "X11Forwarding yes" >/etc/ssh/sshd_config.d/89-enable-x11forwarding.conf
systemctl enable sshd
systemctl restart sshd

# Unlock & pacman & re-lock
steamos-readonly disable
pacman-key --init
pacman-key --populate archlinux
pacman-key --populate holo
pacman -Sy openbsd-netcat pv dog mc python-pip python-pipx
steamos-readonly enable
