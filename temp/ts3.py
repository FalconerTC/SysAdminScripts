#!/usr/bin/python
import telnetlib
import re
import time
import sys


# Read in times from argv
username = "PROMETHEUS"
valid_resp = "error id=0 msg=ok"
message = "The\\sserver\\swill\\sbe\\srestarting\\sin\\s{}\\sseconds."
times = [int(i) for i in sys.argv[1:]]
difs = [i-j for i, j in zip(times[:], times[1:])]
if len(times) > 0:
    difs.append(times[-1])

# Login
tn = telnetlib.Telnet("localhost", "10011")
tn.read_until("command.")
tn.write("login serveradmin password\r\n")
output = tn.read_until(valid_resp)

# Initialization
tn.write("use 1\r\n")
output = tn.read_until(valid_resp)
tn.write("clientupdate client_nickname={}\r\n".format(username))
output = tn.read_until(valid_resp)

# Get current client id
tn.write("whoami\r\n")
pattern = re.compile(ur'client_id=([0-9]+)')
output = tn.read_until(valid_resp)
client_id = re.search(pattern, output).group(1)

# Get list of active channels
tn.write("clientlist\r\n")
pattern = re.compile(ur'cid=([0-9]+)')
output = re.findall(pattern, tn.read_until(valid_resp))

# Convert data and remove duplicates
channels = list(set([int(i) for i in output]))

# Send messages
for i in range(len(times)):
    for cid in channels:
        tn.write("clientmove clid={} cid={}\r\n".format(client_id, cid))
        output = tn.read_until(valid_resp)
        cmd = "sendtextmessage targetmode=2 target={} msg={}\r\n".format(cid,message.format(times[i]))
        tn.write(cmd)
        output = tn.read_until(valid_resp)

    time.sleep(difs[i])

tn.write("quit\r\n")
