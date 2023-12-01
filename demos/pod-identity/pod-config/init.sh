#!/usr/bin/env bash

set -e
set -x

cp /mnt/setup/.bashrc ~/.bashrc
cp /mnt/setup/.vimrc ~/.vimrc
chmod 644 ~/.bashrc
chmod 644 ~/.vimrc

yum install -y jq which tree ncurses vim-common python pip procps-ng

python -m pip install awscli

sleep infinity
