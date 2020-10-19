#!/bin/bash
#

set -x
set -e

# Force Colored output for Vagrant when being run in CI Pipeline
export VAGRANT_FORCE_COLOR=true

check_state(){
if [ "$?" != "0" ]; then
    echo "ERROR Could not bring up last series of devices, there was an error of some kind!"
    exit 1
fi
}

cd simulation

echo "#####################################"
echo "#   Starting the MGMT Server...     #"
echo "#####################################"
vagrant up oob-mgmt-server oob-mgmt-switch

echo "#####################################"
echo "#   Status of all simulated nodes   #"
echo "#####################################"
vagrant status

echo "#####################################"
echo "#  30 sec pause to complete reboots #"
echo "#####################################"

sleep 30

exit 0
