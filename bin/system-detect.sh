#!/bin/bash

if lsb_release_executable="$(which lsb_release 2>/dev/null)" ; then
    lsb_release_desc="lsb:$("lsb_release_executable" -sd 2>/dev/null)"
else
    lsb_release_desc="lsb:unknown"
fi

if [[ ! -r /proc/version ]] ; then
    echo "Error: Cannot read /proc/version" 1>&2
    echo "unknown/$lsb_release_desc"
    exit 1
fi

procversion="$(cat /proc/version)"
case "$procversion" in
MINGW64_NT*)
    # Example from msys: MINGW64_NT-10.0-19044 version 3.2.0-340.x86_64 (runneradmin@fv-az177-418) (gcc version 10.2.0 (GCC) ) 2021-08-02 16:30 UTC
    echo "mingw64/$lsb_release_desc"
    ;;
Linux\ *-microsoft*-WSL2\ *)
    # Example from wsl2: Linux version 5.10.102.1-microsoft-standard-WSL2 (oe-user@oe-host) (x86_64-msft-linux-gcc (GCC) 9.3.0, GNU ld (GNU Binutils) 2.34.0.20200220) #1 SMP Wed Mar 2 00:30:59 UTC 2022
    echo "wsl2/$lsb_release_desc"
    ;;
Linux*)
    echo "linux/$lsb_release_desc"
    ;;
*)
    echo "Error: Unknown system: $procversion" 1>&2
    echo "unknown/$lsb_release_desc"
    exit 1
    ;;
esac
