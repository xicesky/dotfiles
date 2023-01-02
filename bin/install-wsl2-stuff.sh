#!/bin/bash

sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install -y git etckeeper
sudo apt-get install -y python3-pip wslu socat iproute2

mkdir -p ~/bin
WIN_HOME="$(wslpath -a "$(wslvar USERPROFILE)")"
ln -fs "$WIN_HOME" ~/win-home
ln -fs win-home/.m2 ~/.m2
ln -fs win-home/.npmrc ~/.npmrc

# Skip this if dotfiles isn't installed in ~/_dotfiles
# WAIT, we need this to clone in the first place...
if [[ -f ~/_dotfiles/windows/wsl2-ssh-pageant/wsl2-ssh-pageant.exe ]] ; then
    # Make pageant available via
    # https://github.com/BlackReloaded/wsl2-ssh-pageant[wsl2-ssh-pageant]
    WIN_TEMP="$(wslpath -a "$(wslvar TEMP)")"
    windows_destination="$WIN_HOME/bin/wsl2-ssh-pageant.exe"
    linux_destination="$HOME/bin/wsl2-ssh-pageant.exe"
    [[ -f "$windows_destination" ]]
    cp ~/_dotfiles/windows/wsl2-ssh-pageant/wsl2-ssh-pageant.exe "$windows_destination"
    chmod +x "$windows_destination"
    # Symlink to linux for ease of use later
    ln -fs "$windows_destination" "$linux_destination"
    # .zshrc.local will pick it up from here... hopefully.
    # debug using:
    #   ss -a | grep .ssh/agent.sock
fi

sudo apt-get install -y \
    pigz gzrt gzip bzip2 lzma p7zip-full p7zip-rar \
    bc pv netcat-openbsd curl wget nmap ncftp \
    zsh vim mc sudo \
    dnsutils tcpdump \
    apt-transport-https aptitude asciidoctor ruby-rouge \
    ca-certificates jq shellcheck xmlstarlet golang
    
# TODO: Packages requiring apt sources
# helm terraform

# Install via go
go install github.com/mikefarah/yq/v4@latest

# Enable systemd
{
    echo "[boot]"
    echo "systemd=true"
} | sudo sh -c 'cat >/etc/wsl.conf'

chsh -s /usr/bin/zsh

echo "Done. Now \"reboot\" wsl2 via:"
echo "    wsl --shutdown"
echo "    wsl"

