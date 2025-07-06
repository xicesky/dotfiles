#!/bin/bash

# Enable this to use a different X11 server on WSL, such as VcXsrv (https://vcxsrv.com/)
# 
# See:
#   https://stackoverflow.com/questions/61110603/how-to-set-up-working-x11-forwarding-on-wsl2
# Make sure your windows firewall lets WSL on port 6000 (from 172.16.0.0/12):
#   https://github.com/cascadium/wsl-windows-toolbar-launcher#firewall-rules
# I strongly recommend to use an .Xauthority file:
#   * Run your x server without auth first
#   * Run: xauth generate $DISPLAY
#   * Run: cp ~/.Xauthority ~/win-home/
#   * Restart your X11 server with the .Xauthority file in your home dir, e.g. for VcXsrc
#       replace the "-ac" option by:
#       -auth C:\Users\<your login>\.Xauthority

if iswsl2 ; then
    cat <<"EOF"
export ORIGINAL_DISPLAY="$DISPLAY"
export DISPLAY=$(ip route list default | awk '{print $3}'):0
export LIBGL_ALWAYS_INDIRECT=1

switch-x11() {
    local temp="$DISPLAY"
    DISPLAY="$ORIGINAL_DISPLAY"
    ORIGINAL_DISPLAY="$temp"
    echo "Set DISPLAY to $DISPLAY" >&2
}

EOF
fi
