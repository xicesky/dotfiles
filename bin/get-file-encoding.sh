#!/bin/bash

file -bi "$1" | grep -oP '(?<=charset=).*'

