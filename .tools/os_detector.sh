#!/bin/zsh

if [[ $OSTYPE == *"darwin"* ]]; then
    OS="macos"
elif [[ $OSTYPE == *"linux"* ]]; then
    OS="linux"
fi
