#!/bin/sh

set -ex
if [ ! -d "/ironmq/data" ]; then
    mkdir /ironmq/data
fi
if [ ! -d "/ironmq/data/log-backup" ]; then
    mkdir /ironmq/data/log-backup
fi
cp /ironmq/data/ironmq/data/LOG /ironmq/data/log-backup/`date +%s`.log
rm -f /ironmq/data/ironmq/data/*
