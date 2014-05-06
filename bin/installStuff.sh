#!/bin/sh

## Most important
aptitude install etckeeper
git config --global user.name "Markus Dangl"
git config --global user.email "markus@q1cc.net"
( cd /etc ; git commit --amend --reset-author ; )

## Setup the console / terminal correctly
aptitude install console-setup ncurses-term

## Then install this
aptitude install \
    vim htop iotop iptraf p7zip-full mc netcat curl wget \
    nmap screen checkinstall cclive pigz gzrt \
    gzip bzip2 hwinfo ltrace strace lvm2 lzma \
    ncftp netcat-openbsd parted p7zip-rar pv \
    gdisk bc xauth zsh sudo dnsutils tcpdump \
    subversion git git-svn

## Comment this out if you mind larger downloads
aptitude install \
    linux-headers-amd64

## Maybe this
#aptitude install \
#    sl vim-gtk screenie dosfstools cryptsetup gparted arora \
#    cclive lshw hwinfo

## Services (have to decide on those)
#aptitude install \
#    ntop ntp xinetd anacron
aptitude install \
    mlocate

## More stuff (i dont use that often)
#aptitude install \
#    byobu memtest86+ grub-invaders

