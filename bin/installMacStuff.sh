#!/bin/sh
set -e

do_sudo() {
    if [ "$1" == "-n" ] ; then shift
    else echo "Please enter your password to run the following command as root:"; fi
    echo "    $@"
    sudo "$@"
}

# Installs my stuff on OSX
# TODO:
#   Proper option parser
#   https://pqrs.org/osx/karabiner/      <=   http://apple.stackexchange.com/questions/116617/how-to-separate-mouse-and-trackpad-settings
#   More stuff: https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/

FAST=false
if [ "$1" == "--fast" ] ; then FAST=true ; fi

if ! $FAST ; then
    # Check for private keys beforehand
    if [ ! -d "$HOME/Google Drive/Keys/ssh" ] ; then
        echo "Please install Google Drive and sync to get your keys and stuff in place."
    fi

    # Install homebrew
    if ! which brew ; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew update

    if [ ! -d "$HOME/.ssh" ] ; then
        echo "Please accept the connection and then cancel with CTRL+C at the password prompt."
        echo "This will create the ssh directory with the correct permissions and initialize known_hosts."
        ssh markus@light.q1cc.net
    fi

    # Set up ssh keys and add the main key
    if [ ! -e "$HOME/.ssh/keys" ] ; then
        (
            cd "$HOME/.ssh"
            ln -s ~/Google\ Drive/Keys/ssh keys
        )
    fi
    ssh-add "$HOME/.ssh/keys/sky@q1cc.net"
    #ssh-add -l

    # Git
    brew install git
    git config --global alias.st status
    git config --global user.name "Markus Dangl"
    git config --global user.email "sky@q1cc.net"

    # Load dotfiles and set up basics
    if [ ! -e "$HOME/_dotfiles" ] ; then
        (
            cd $HOME
            git clone "git@github.com:xicesky/dotfiles.git" _dotfiles
            [ -e .vim ] || ln -s _dotfiles/vim/.vim
            [ -e .vimrc ] || ln -s _dotfiles/vim/.vimrc
            [ -e .zshrc ] || ln -s _dotfiles/zsh/.zsh{env,rc,rc.local} .
        )
    fi
fi

# Install stuff using homebrew
brew install vim --override-system-vi --override-system-vim
brew install htop --with-ncurses
brew install coreutils zsh wget screen mc

# After installing zsh:
# LOC_ZSH="`which zsh`"
# (???) sudo echo "$LOC_ZSH" >>/etc/shells (?wouldn't work that way!)
# chsh -s "$LOC_ZSH"

# Settings
# TODO: Settings should be seperate (available via option?)
# Disable horrible mouse accel
defaults write .GlobalPreferences com.apple.mouse.scaling -1

# Start creating the database for locate
echo "Starting to create locate DB, enter your sudo password to run:"
do_sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist

