#!/bin/bash

cd() {
    # shellcheck disable=SC2164
    pushd "$@" >/dev/null
}
