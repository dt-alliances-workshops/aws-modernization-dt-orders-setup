#!/bin/bash

echo "Killing CPU waster 'yes' command with following PIDS:"
ps -ef|grep yes | grep -vE 'grep' | awk '{print $2}'
kill $(ps -ef|grep yes | grep -vE 'grep' | awk '{print $2}')
echo ""
echo "Done."