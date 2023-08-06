#!/bin/bash

# Check if we can find android sdk or platform tools
if [ -d "/usr/local/share/android-sdk" ] ; then
    echo 'export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"'
    append_to_path "$ANDROID_SDK_ROOT/platform-tools"
elif [[ -d "$HOME/Library/Android/sdk/platform-tools" ]] ; then
    # No? Check if we have platform tools at least
    append_to_path "$HOME/Library/Android/sdk/platform-tools"
fi
