vim
===

Vim configuration, plugins, ...
We are using pathogen to support older vim versions, thus all plugins belong in the
.vim/bundle directory, each in their own seperate directory. They are often installed
as git submodules - see https://gist.github.com/romainl/9970697

I like this page for plugins: https://vimawesome.com/

Installation
============

```
# Clone dotfiles
git clone "git@github.com:xicesky/dotfiles.git" _dotfiles

# Init submodules (Our plugins are held in submodules)
cd _dotfiles
git submodule init
git submodule update

# Symlink the config to your home directory
cd ~
ln -s _dotfiles/vim/.vim
ln -s _dotfiles/vim/.vimrc
``` 

"Changelog"
===========

Added http://www.vim.org/scripts/script.php?script_id=90
    vcscommand.vim : CVS/SVN/SVK/git/hg/bzr integration plugin
    vcscommand-1.99.47.zip

Added faster diffget maps: http://blog.binchen.org/?p=601

Settings that are likely to be localized are now in .vim/local

Added DirDiff.vim plugin: http://www.vim.org/scripts/script.php?script_id=102

Edited the inkpot colors in gvim to my taste.

Added LargeFile script: http://www.vim.org/scripts/script.php?script_id=1506

Added gnupg.vim plugin: http://www.vim.org/scripts/script.php?script_id=3645

Removed all the go stuff, it's old anyways.
Removed plugins that i rarely used: vcscommand, jinja, DirDiff

All plugins are now in .vim/bundle and can be managed individually (thanks for pathogen!)
    (vim 8 also has package management, but we are using pathogen to support older versions).

Added vim-airline: https://github.com/vim-airline/vim-airline

Now using vim-dim as default colorscheme: https://github.com/jeffkreeftmeijer/vim-dim
