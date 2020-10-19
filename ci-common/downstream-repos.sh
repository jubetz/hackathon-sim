#!/bin/bash

set -e

check_state(){
if [ "$?" != "0" ]; then
    echo "ERROR from last operation!"
    exit 1
fi
}

# usage: update submodule "project-id" "project-name"
update_submodule(){
    NEW_BRANCH_NAME=dev-cldemo-update-$CI_COMMIT_SHORT_SHA

    echo "Currently in directory: $(pwd)"

    #TODO: use API to dynamically find repos that are tagged or named for official support
    #Then perform same steps on each repo. For now just hard coding.
    CI_PROJECT_ID=$1
    DOWNSTREAM_PROJECT_NAME=$2
    echo "Creating Branch & Updating Submodule on: $DOWNSTREAM_PROJECT_NAME"

    #### Section to update the cldemo2 submodule and push to new branch
    git clone -b dev --recurse-submodules git@gitlab.com:cumulus-consulting/goldenturtle/$DOWNSTREAM_PROJECT_NAME
    cd $DOWNSTREAM_PROJECT_NAME

    # checkout new branch locally
    git checkout -b $NEW_BRANCH_NAME

    # pass in the user and email from this CI run
    git config user.email $GITLAB_USER_EMAIL
    git config user.name $GITLAB_USER_NAME

    # update submodule to recent, stage for commit and commit
    git submodule update --remote
    git add cldemo2
    git commit -m "cldemo2 update: $CI_COMMIT_MESSAGE" 

    # push changes and new branch to gitlab and start CI run
    git push origin $NEW_BRANCH_NAME

    sleep 5

    #set branch as protected since we need protected variables on the project
    CURL_RESPONSE=`curl -X POST "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/protected_branches?name=${NEW_BRANCH_NAME}" \
	    --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}";`

    echo "Response from GITLAB:"
    echo $CURL_RESPONSE | jq '.'

    #create a Merge Request on the project for the new branch
    BODY="{
        \"id\": ${CI_PROJECT_ID},
        \"source_branch\": \"${NEW_BRANCH_NAME}\",
        \"target_branch\": \"dev\",
        \"title\": \"${NEW_BRANCH_NAME}\"
    }";

    echo "Posting API call to create merge request"    

    CURL_RESPONSE=`curl -X POST "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests" \
        --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "${BODY}";`
    
    echo "Response from GITLAB:"
    echo $CURL_RESPONSE | jq '.'

    echo "Opened a new merge request: ${NEW_BRANCH_NAME} for this update"
    
    echo "Setting Auto Merge if CI pipeline passes"
    #get the merge request iid from the last response
    MR_IID=`echo $CURL_RESPONSE | jq '.["iid"]'`
    #accept MR 
    
    #BODY="{
    #    \"id\": ${CI_PROJECT_ID},
    #    \"merge_request_iid\": \"${MR_IID}\",
    #    \"merge_when_pipeline_succeeds\": true,
    #    \"should_remove_source_branch\": true
    #}";
        
    BODY="{
        \"id\": ${CI_PROJECT_ID},
        \"merge_request_iid\": \"${MR_IID}\",
        \"merge_when_pipeline_succeeds\": true
    }";
    
    sleep 10
    
    echo "About to PUT to accept MR upon pipeline success"
    CURL_RESPONSE=`curl -X PUT "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests/${MR_IID}/merge" \
        --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "${BODY}";`
    
    echo "Response from GITLAB:"
    echo $CURL_RESPONSE | jq '.'
    
    cd ..
    echo "Done with $DOWNSTREAM_PROJECT_NAME"
}

echo "calling subroutine for cldemo2-air-builder"
update_submodule "18234618" "cldemo2-air-builder"

#echo "calling subroutine for dc_configs_vxlan_evpnl2only"
#update_submodule "15489287" "dc_configs_vxlan_evpnl2only"

#echo "calling subroutine for dc_configs_vxlan_evpncent"
#update_submodule "15489348" "dc_configs_vxlan_evpncent"

#echo "calling subroutine for dc_configs_vxlan_evpnsym"
#update_submodule "15490096" "dc_configs_vxlan_evpnsym"

exit 0
