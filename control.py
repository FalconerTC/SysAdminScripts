#!/usr/bin/env python3.5
"""Control script for starting and maintaining servers."""
from subprocess import run, check_output, CalledProcessError
import argparse
from configparser import ConfigParser, ExtendedInterpolation
from time import sleep

__authors__ = 'spig', 'knytemere'


# Function declarations
# Get PID of requested service
def get_pid(which):
    pid = ''
    screen_name = ''
    if which == 'starbound':
        screen_name = config['Starbound']['screen_name']
    elif which == 'killingfloor':
        screen_name = config['KillingFloor']['screen_name']
    # run(['ps fax | grep ' + screen_name + ' | grep SCREEN | awk \'{ print $1 } \''], shell=True)
    # This returns, as a byte string, the PID of the process that has a command line section matching the screen_name.
    # It essentially mimics the functionality of the above line but I'm not sure if it should be removed yet.
    try:
        pid = check_output(['pgrep', '-f', screen_name]).decode("utf-8").strip()
        # decodes PID from byte string to string
    except CalledProcessError:
        print("Could not find PID. Is the service running?")
    return pid


# Start service
def start(which):
    screen_name = ''
    start_cmd = ''
    game_path = ''
    if which == 'starbound':
        screen_name = config['Starbound']['screen_name']
        start_cmd = config['Starbound']['start_cmd']
        game_path = config['Starbound']['game_path']
    elif which == 'killingfloor':
        screen_name = config['KillingFloor']['screen_name']
        start_cmd = config['KillingFloor']['start_cmd']
        game_path = config['KillingFloor']['game_path']
    print("Attempting to start server...")
    pid = get_pid(which)
    if pid:
        print("Server already running.")
        return_code = 0
    else:
        start_call = run(['screen', '-A', '-m', '-d', '-S', screen_name, start_cmd], cwd=game_path)
        return_code = start_call.returncode
        print("\nServer running in detached screen.")
        print("Screen name: " + screen_name)
    return return_code


# Stop service
def stop(which):
    screen_name = ''
    if which == 'starbound':
        screen_name = config['Starbound']['screen_name']
    elif which == 'killingfloor':
        screen_name = config['KillingFloor']['screen_name']
    pid = get_pid(which)
    if pid:
        start_call = run(['screen -X -S ' + screen_name + ' kill'], shell=True)
        return_code = start_call.returncode
        print("Server stopped successfully.")
        sleep(0.2)
    else:
        print("Server not running.")
        return_code = 0
    return return_code


# Restart service
def restart(which):
    print("Stopping server...")
    stop(which)
    print("Starting server...")
    return_code = start(which)  # preserve the return value from start to use as return value of restart
    return return_code


# Status of service
def status(which):
    pid = get_pid(which)
    if pid:
        print("Server running.")
        print("PID: " + str(pid))
        return_code = 0
    else:
        print("Server not running.")
        return_code = 1
    return return_code


# Update the server
def update(which):
    steam_username = ''
    game_dir = ''
    game_id = ''
    if which == 'starbound':
        steam_username = config['Starbound']['steam_username']
        game_dir = config['Starbound']['game_dir']
        game_id = config['Starbound']['game_id']
    elif which == 'killingfloor':
        steam_username = config['KillingFloor']['steam_username']
        game_dir = config['KillingFloor']['game_dir']
        game_id = config['KillingFloor']['game_id']
    print("Running updater...")
    start_call = run([config['Execs']['steam_cmd'] + '+login ' + steam_username + ' +force_install_dir ' + game_dir +
                      ' +app_update ' + game_id + ' validate +quit'], shell=True)
    return start_call.returncode


# Begin main program code
parser = argparse.ArgumentParser(prog="Server control program", description="This script controls the servers "
                                 "available on this server.")


parser.add_argument('server', choices=['killingfloor', 'starbound'], help="Which server program to run")
parser.add_argument('function', choices=['start', 'stop', 'restart', 'status', 'update'], help="What function to "
                    "perform with specified server.")
parser.add_argument('-v', '--verbose', help="Verbosity.", required=False)
args = parser.parse_args()
server = args.server
function = args.function
verbosity = args.verbose

config = ConfigParser(interpolation=ExtendedInterpolation())
config.read('./settings/config.cfg')

if verbosity:
    print("Server value: " + server)
if verbosity:
    print("Function value: " + function)
if verbosity:
    print("This is where the conditionals begin.")
if server:
    if function == 'start':
        if verbosity:
            print("Start call begins.")
        start(server)
    elif function == 'stop':
        if verbosity:
            print("Stop call begins.")
        stop(server)
    elif function == 'restart':
        if verbosity:
            print("Restart call begins.")
        restart(server)
    elif function == 'status':
        if verbosity:
            print("Status call begins.")
        status(server)
    elif function == 'update':
        if verbosity:
            print("Update call begins.")
        update(server)
if verbosity:
    print("This is where the conditionals end.")
