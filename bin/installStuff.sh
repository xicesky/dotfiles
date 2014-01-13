#!/bin/sh

# Setup the console / terminal correctly
aptitude install console-setup
aptitude install ncurses-term

# Most important
aptitude install etckeeper

# then this
aptitude install \
    vim-nox mlocate htop iotop ntop iptraf arora p7zip-full mc netcat curl wget \
    nmap screen byobu checkinstall cclive sl pigz grub-invaders gzrt gparted \
    vim-gtk gzip bzip2 hwinfo linux-headers-amd64 ltrace strace lvm2 lzma \
    memtest86+ ncftp netcat-openbsd ntp parted p7zip-rar pv screenie subversion \
    xinetd \
    gdisk bc xauth dosfstools cryptsetup zsh \
    debootstrap grml-debootstrap

