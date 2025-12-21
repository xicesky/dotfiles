Symlink service to $HOME/.config/systemd/user
    ln -s -t .config/systemd/user ../../../_dotfiles/systemd/jellyfin-flatpak/jellyfin.service
Then use e.g.:
    systemctl --user enable jellyfin

For further reference see https://wiki.archlinux.org/title/systemd/User

