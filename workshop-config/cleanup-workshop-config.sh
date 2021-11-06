#!/bin/bash

source ./_workshop-config.lib

run_monaco_delete() {
    # run monaco as code script
    PROJECT_BASE_PATH=./monaco-files/projects
    PROJECT=$1
    ENVIONMENT_FILE=./monaco-files/environments.yaml

    echo "-------------------------------------------------------------------"
    echo "Deleting project: $PROJECT"
    echo "-------------------------------------------------------------------"
    cp $PROJECT_BASE_PATH/$PROJECT/delete.txt $PROJECT_BASE_PATH/delete.yaml 
    export NEW_CLI=1 && export DT_BASEURL=$DT_BASEURL && export DT_API_TOKEN=$DT_API_TOKEN && ./monaco deploy -v --environments $ENVIONMENT_FILE --project $PROJECT $PROJECT_BASE_PATH
    rm $PROJECT_BASE_PATH/delete.yaml 
}

reset_custom_dynatrace_config() {
    setFrequentIssueDetectionOn
    setServiceAnomalyDetection ./custom/service-anomalydetectionDefault.json
}

# this supports the clean up to run without a prompt.  
# Just pass in an argument ./cleanup-workshop-config.sh Y
if [ -z $1 ]; then
    echo "==================================================================="
    echo "About to Delete Workshop Dynatrace configuration on $DT_BASEURL"
    echo "==================================================================="
    read -p "Proceed? (y/n) : " REPLY;
else
    REPLY=$1
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then

    echo ""
    echo "*** Removing Dynatrace config ***"
    echo

    # need to do this so that the monaco valdiation does not fail
    # even though you are not running the dashboard project, monaco
    # still valdiates all the projects in the projects folders 
    export OWNER=DUMMY_PLACEHOLDER
    run_monaco_delete monolith-vm
    run_monaco_delete cluster
    run_monaco_delete services-vm
    run_monaco_delete db
    #run_monaco_delete synthetics  # if add this, need to adjust token permission instructions

    reset_custom_dynatrace_config

    echo ""
    echo "*** Done Removing Dynatrace config ***"
    echo ""
fi