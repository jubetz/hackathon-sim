#!/bin/bash

set -x

cd simulation

date
vagrant destroy -f

#clean the gitlab-runners for inside simulations that may be present
echo "Cleanup old oob-mgmt-server inside runners"
RUNNER_IDS=`curl --header "PRIVATE-TOKEN: $API_KEY" "https://gitlab.com/api/v4/runners?tag_list=${CI_PROJECT_NAME}:oob-mgmt" |  jq '.[] | .id'`
for id in $RUNNER_IDS
do
  curl --request DELETE --header "PRIVATE-TOKEN: $API_KEY" "https://gitlab.com/api/v4/runners/$id"
done

echo "Finished."
