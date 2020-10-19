#!/bin/bash

set -x
set -e

check_state(){
if [ "$?" != "0" ]; then
    echo "ERROR Could not bring up last series of devices, there was an error of some kind!"
    exit 1
fi
}

wait_oob_mgmt_server()
{ # Wait function for oob-mgmt-server
  limit=10
  iter=0
  vagrant ssh oob-mgmt-server -c "echo 'ssh successful'"
  while [ $? -gt 0 ] && [ $iter -lt $limit ]
  do
    sleep 5
    echo "Trying to ssh on oob-mgmt-server"
    ((iter++))
    vagrant ssh oob-mgmt-server -c "echo 'ssh successful'"
  done
}

kvm_ok()
{
    set +xe
    lscpu | grep -i virt &> /dev/null
    if [ $? -gt 0 ]; then
        echo "kvm not ok"
    fi
    lsmod | grep -i kvm &> /dev/null
    if [ $? -gt 0 ]; then
        echo "kvm not ok"
    fi
    set -xe
}

echo "Vagrant version is: $(/usr/bin/vagrant --version)"

echo "Libvirt version is: $(/usr/sbin/libvirtd --version)"

echo "Check that the machine supports virtualization..."
kvm_ok

echo "Checking/Installing Vagrant Plugins..."
VAGRANT_LIBVIRT_INSTALLED="false"
for plugin in `vagrant plugin list`
  do
    if [ "$plugin" = 'vagrant-libvirt' ]
    then
      VAGRANT_LIBVIRT_INSTALLED="true"
    fi
done
if [ "$VAGRANT_LIBVIRT_INSTALLED" = "false" ]
then
  vagrant plugin install vagrant-libvirt
fi

#clean up libvirt simulations from previous failed runs
echo "Cleaning pre-existing simulations"
vms=$(virsh list --all | grep ".*\ simulation_${CI_PROJECT_NAME}_" | awk '{print $2}')

for item in $vms; do
  echo "$item"
    # check if its powered off state
    vm_state=`virsh list --all | grep $item | awk '{print $3}'`
    if [ "$vm_state" = "running" ] ; then
      virsh destroy $item
    fi
    virsh undefine $item
    virsh vol-delete --pool default $item".img"
done

#clean up old gitlab-runners from inside simulations that may be present
echo "Cleanup old oob-mgmt-server inside runners"
RUNNER_IDS=`curl --header "PRIVATE-TOKEN: $API_KEY" "https://gitlab.com/api/v4/runners?tag_list=${CI_PROJECT_NAME}:oob-mgmt" |  jq '.[] | .id'`
for id in $RUNNER_IDS
do
  curl --request DELETE --header "PRIVATE-TOKEN: $API_KEY" "https://gitlab.com/api/v4/runners/$id"
done
