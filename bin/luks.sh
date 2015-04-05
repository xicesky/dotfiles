#!/bin/sh

# LUKS
UUID="360325d3-2766-4aed-8881-f5683b8726ba"
LUKS_NAME="encrypted"
LUKS_DEV="/dev/mapper/$LUKS_NAME"

# LVM
VG="vg0"
LV="data"
LV_DEV="/dev/$VG/$LV"

# Mountpoint
MNT_PATH="/data"

################################################################################

luks_open() {
    [ -e "$LUKS_DEV" ] && return 0
    cryptsetup open -v --type luks $OPT_LUKS UUID="$UUID" "$LUKS_NAME"
}

luks_close() {
    [ -e "$LUKS_DEV" ] || return 0
    cryptsetup close -v "$LUKS_NAME"
}

vg_open() {
    [ -e "$LV_DEV" ] && return 0
    vgchange -a y "$VG"
}

vg_close() {
    [ -e "$LV_DEV" ] || return 0
    vgchange -a n "$VG"
}

do_mount() {
    # No state control yet, just ignore errors
    mount $OPT_MOUNT "$LV_DEV" "$MNT_PATH" || true
}

do_umount() {
    # No state control yet, just ignore errors
    umount "$MNT_PATH" || true
}

################################################################################

# Parse cmd
OPT_LUKS=""
OPT_MOUNT=""
MODE=""

while test -n "$1" ; do
    case "$1" in
        -r|--ro|--readonly|--read-only)
            OPT_LUKS="$OPT_LUKS --readonly"
            OPT_MOUNT="--read-only"
            ;;
        --*)
            echo "Unkown option: $1" 1>&2
            exit 1
            ;;
        *)
            test -z "$MODE" || {
                echo "Mode already set to $MODE" 1>&2
                exit 1
            }
            MODE="$1"
            ;;
    esac
    shift
done

case "$MODE" in
    "open")
        set -x
        luks_open
        ;;
    "mount")
        set -e
        set -x
        [ -e "$LUKS_DEV" ] || luks_open
        [ -e "$LV_DEV" ] || vg_open
        do_mount
        ;;
    "close"|*)
        #set -x
        do_umount
        vg_close
        luks_close
        ;;
esac

