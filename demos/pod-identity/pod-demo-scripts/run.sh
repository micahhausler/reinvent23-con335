#!/usr/bin/env bash

FILE=$1

while IFS= read -u 3 -r LINE
do
    if [[ $LINE == "" ]]; then
        continue
    fi
    if [[ $LINE == \#* ]]; then
        echo $LINE
        continue
    fi
    echo $LINE
    read next
    if [[ $next == s* ]]; then
        continue
    fi
    eval $LINE
    read next
    if [[ $next == s* ]]; then
        continue
    fi
    clear

done 3< "$FILE"
