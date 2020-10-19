#!/bin/bash
#

set -x

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
echo "#   Start everything                #"
echo "#####################################"

vagrant up /leaf/ /spine/ /border/ /fw/
check_state

vagrant up /server0/
check_state

echo "#####################################"
echo "#   Status of all simulated nodes   #"
echo "#####################################"
vagrant status

echo "1 min pause to allow devices to reboot and ZTP"
sleep 60

exit 0
