#!/bin/zsh

if [[ $OSTYPE == *"darwin"* ]]; then
    export OS_TYPE="macos"
elif [[ $OSTYPE == *"linux"* ]]; then
    export OS_TYPE="linux"
fi
