#!/bin/bash

set -x
set -e

#Remove the gitlab-runner for the oob-mgmt-server, it's dead now
echo "Cleanup old oob-mgmt-server inside runners"
RUNNER_IDS=`curl --header "PRIVATE-TOKEN: ${1}" "https://gitlab.com/api/v4/runners?tag_list=${2}:oob-mgmt" |  jq '.[] | .id'`
for id in $RUNNER_IDS
do
  curl --request DELETE --header "PRIVATE-TOKEN: ${1}" "https://gitlab.com/api/v4/runners/$id"
done

echo "Finished."
