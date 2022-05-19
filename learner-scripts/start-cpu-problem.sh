#!/bin/bash

yes > /dev/null &
yes > /dev/null &
yes > /dev/null &

echo "Started CPU waster 'yes' command with PIDS:"
ps -ef|grep yes | grep -vE 'grep' | awk '{print $2}'