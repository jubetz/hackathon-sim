#!/bin/bash
cd simulation

####SETUP
SLEEP_SECONDS=2
RETRIES=5
NETQ_USERNAME=jbetz@cumulusnetworks.com
NETQ_PASSWORD=WRONG-PASSWORD
NETQ_CHECKS="agents interfaces mtu vlan ntp"

function error() {
  echo -e "\e[0;33mERROR: Provisioning of the simulation failed while running the command $BASH_COMMAND at line $BASH_LINENO.\e[0m" >&2
  if [ "$debug" != "true" ]; then
    echo " >>>Destroying Simulation<<<"
    vagrant destroy -f
  fi
  exit 1
}

trap error ERR

source ../tests/pipeline_failure_behavior
echo "Starting to run tests...."

#commented out sed -e so we don't fail ci for grep return code checks
#set -e
set -x

# Force Colored output for Vagrant when being run in CI Pipeline
export VAGRANT_FORCE_COLOR=true


#######################################################
# TESTS RUN FROM OOB-MGMT-SERVER 
#######################################################
vagrant ssh oob-mgmt-server -c "bash /home/cumulus/tests/tests_oob_server_inside.sh"


# This is NetQ checks/tests v1 - this is disabled in favor of API method
# Makes netq check calls on netq-ts directly
#
#vagrant ssh netq-ts -c "bash tests/tests_netq-ts_inside.sh"
#


#######################################################
# NETQ TESTS USING API  
#######################################################
# Get auth token
NETQ_API_TOKEN=`curl -s -X POST "https://api.netq.cumulusnetworks.com/netq/auth/v1/login" -H "Content-Type: application/json" -d "{ \"username\": \"$NETQ_USERNAME\", \"password\": \"$NETQ_PASSWORD\"}" | jq -r .access_token`

### dump list of agents:


### Loop through the list of NETQ_CHECKS
for netq_check in $NETQ_CHECKS
do

  #start a validation, store the job id
  CHECK_JOB_ID=`curl -s -X POST https://api.netq.cumulusnetworks.com/netq/telemetry/v1/object/check/schedule -H "Authorization: $NETQ_API_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" -d "{\"validation_type\": ["$netq_check"]}" | jq -r '.data[].jobid'`
  echo "$netq_check Check ID: $CHECK_JOB_ID"

  #### EXAMPLE RESPONSE:
  #root@chai:/mnt/nvme/justin-cloud# curl -s -X POST https://api.netq.cumulusnetworks.com/netq/telemetry/v1/object/check/schedule -H "Authorization: $NETQ_API_TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"validation_type": ["bgp"]} ' | jq
  #{
  #  "data": [
  #    {
  #      "jobid": "a61f16e6-92e0-4934-a713-e757f9fd6875",
  #      "status": "success",
  #      "validation_type": "bgp"
  #    }
  #  ]
  #}

  #get validation results
  # Calling for validtion results with this GET string seems to return the result of every job. We just want the most recent one.
  # All we have to work with is the jobid that was returned.  In limited testing, it seems like the most recent job results (once finished) are the first data element 'jq .data[0]'
  # There's no callback to know when the validation is finished....
  # We have to just check the results and look for our jobid. Our jobid should be in data[0].jobid

  #This returns just the jobid from the first element in data[]
  #curl -s -X GET "https://api.netq.cumulusnetworks.com/netq/telemetry/v1/object/check?by=ondemand&proto=evpn&time={`date +%s`}&duration=1" -H "Content-Type: application/json" -H "Authorization: $NETQ_API_TOKEN" | jq '.data[0].jobid' | grep $CHECK_JOB_ID


  num_loops=0
  last_code=1
  while [ "1" == "$last_code" ]; do
      sleep $SLEEP_SECONDS
      echo "Checking for validation completion"
      curl -s -X GET "https://api.netq.cumulusnetworks.com/netq/telemetry/v1/object/check?by=ondemand&proto=$netq_check&time={`date +%s`}&duration=1" -H "Content-Type: application/json" -H "Authorization: $NETQ_API_TOKEN" | jq '.data[0].jobid' | grep $CHECK_JOB_ID
      last_code=$?
      if [ "$num_loops" == $RETRIES ]; then
        echo "Failed to get NetQ validation results after $RETRIES times"
        exit 1
      fi
      ((num_loops++))
  done

  echo "Found our jobid: $CHECK_JOB_ID (should match below)"
  curl -s -X GET "https://api.netq.cumulusnetworks.com/netq/telemetry/v1/object/check?by=ondemand&proto=$netq_check&time={`date +%s`}&duration=1" -H "Content-Type: application/json" -H "Authorization: $NETQ_API_TOKEN" | jq '.data[0]'


done


