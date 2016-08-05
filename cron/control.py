#!/usr/bin/env python3.5
"""Control script for starting and maintaining servers."""
from subprocess import run
import argparse

__authors__ = 'spig', 'knytemere'
GAME_PATH = 0
SCREEN_NAME = 0

#  Get PID of requested service
def get_pid():
    pid = run(['ps fax | grep $SCREEN_NAME | grep SCREEN | awk \'{ print $1 } \''])
    return pid


parser = argparse.ArgumentParser(prog="Server control program", description="This script controls the servers "
                                                                            "available on this server.")
parser.add_argument('server', choices=['killingfloor','starbound'], help="Which server program to run", required=True)
parser.add_argument('function', choices=['start', 'stop', 'restart', 'status', 'update'], help="What function to "
                    "perform with specified server.", required=True)
args = parser.parse_args()

def start():
    print("Attempting to start server...")
    pid = get_pid()
    if pid:
        print("Server already running.")
        return 0
    else:
