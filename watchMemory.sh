#!/bin/bash

while [ true ]; do
    echo $(date +%X): $(free -mht | tail -n1) >> /home/spig/mem.log
    sleep 30
done
