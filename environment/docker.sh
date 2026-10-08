#!/bin/bash

# Set DOCKER_HOST if not already set.
# FIXME: How to determine if we are using podman or docker?
if which podman >/dev/null 2>&1 ; then
    # And this is linux-specific, i don't know of a way to find this socket.
    # we also should NOT check that it exists, because the service might not be up yet.
    # DO NOT use the existing variable here, since this script might be run by regenerate_env
    # in an environment where the DOCKER_HOST is just wrong!
    #DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$UID/podman/podman.sock}"
    DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"
fi
export DOCKER_HOST
echo "export DOCKER_HOST=$(printf "%q" "$DOCKER_HOST")"
