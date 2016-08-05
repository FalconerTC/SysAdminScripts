#!/usr/bin/env python3.5
"""Restart Starbound server if it is not running."""
from subprocess import run
from time import sleep
__authors__ = 'spig', 'knytemere'
while True:
    server_process = run(['/home/spig/scripts/control.sh starbound status &> /dev/null'], shell=True)
    if server_process.returncode:
        run(['echo \"$(date +%X), Restarting Starbound Server.\"'], shell=True)
        run(['/home/spig/scripts/control.sh starbound restart &> /dev/null'], shell=True)
    else:
        run(['echo \"$(date +%X), Starbound still running.\"'], shell=True)
    sleep(5)
