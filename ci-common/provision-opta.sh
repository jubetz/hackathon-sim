#!/bin/bash

set -e

check_state(){
if [ "$?" != "0" ]; then
    echo "ERROR on previous command - Exit with failure"
    exit 1
fi
}

echo "NetQ Master Boostrap...takes several minutes"
netq_bootstrap=`echo $NETQ_BOOTSTRAP_TARBALL | base64 -d`
netq bootstrap master interface eth0 tarball $netq_bootstrap > /dev/null 2>&1

echo "Bootstrap complete."
echo ""

echo "NetQ OPTA Install...takes several more minutes"
netq_install=`echo $NETQ_OPTA_TARBALL | base64 -d`
netq install opta standalone full interface eth0 bundle $netq_install config-key $NETQ_CONFIG_KEY

# For multi-site cloud deployments, a site dedicated for CI is required
# A premise name must be specificied in the CI config. This is configured as an environment variable in gitlab CI settings.
echo "Adding NetQ CLI Server"
netq config add cli server api.netq.cumulusnetworks.com access-key $NETQ_ACCESS_KEY secret-key $NETQ_SECRET_KEY premise $NETQ_PREMISE_NAME port 443

echo "Restarting NetQ agent and cli"
netq config restart cli
sleep 5
netq config restart agent
