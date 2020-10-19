#!/bin/bash

set -x
set -e

echo "Forced NetQ processing time after provisioning"
sleep 60

echo "netq show agents"
netq show agents

echo "netq show inv br"
netq show inventory br

echo "netq check cl-version"
netq check cl-version include 0

echo "netq check agents include 0"
netq check agents include 0

#echo "netq check interfaces"
netq check interfaces
netq show interfaces

echo "netq check mtu"
netq check mtu include 0
netq check mtu include 1
netq check mtu include 2

echo "netq check ntp"
netq show ntp
#netq check ntp include 0

echo "netq check agents"
netq show agents
