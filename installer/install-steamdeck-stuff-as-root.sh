#!/bin/sh

## Most important
pacman -S etckeeper
git config --global user.name "Markus Dangl"
git config --global user.email "markus@q1cc.net"
git config --global init.defaultBranch main
git config --global alias.st status
etckeeper init
etckeeper commit

## Then install this
aptitude install \
    vim htop iotop iptraf p7zip-full mc netcat curl wget \
    nmap screen checkinstall cclive pigz gzrt \
    gzip bzip2 hwinfo ltrace strace lvm2 lzma \
    ncftp netcat-openbsd parted p7zip-rar pv \
    gdisk bc xauth zsh sudo dnsutils tcpdump \
    subversion git git-svn gnupg2

# Already installed on steam deck:
#   vim htop iotop p7zip curl wget tmux
#   gzip bzip2 strace lzma zsh
# Not found in pacman...?
#   bc
# Replacments
#   dig -> dog (because we don't want to install the compete "bind" package)
pacman -S openbsd-netcat pv dog
