#!/bin/bash
check_state(){
if [ "$?" != "0" ]; then
    echo "ERROR Could not bring up last series of devices, there was an error of some kind!"
    exit 1
fi
}

echo "Test Ansible Ping for all nodes"
ansible exit:leaf:spine:server* -m ping
check_state

