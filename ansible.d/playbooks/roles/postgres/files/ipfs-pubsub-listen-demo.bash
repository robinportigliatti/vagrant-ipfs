#!/bin/bash

mkdir -p /tmp/demo/pg_wal
ipfs pubsub sub demo | while read -r line
do
    read -a arr <<< $line

    echo "/tmp/demo/pg_wal/${arr[1]}"
    ipfs get ${arr[0]} --output="/tmp/demo/pg_wal/${arr[1]}"
    echo "File ${arr[1]} ready to be processed"
done
