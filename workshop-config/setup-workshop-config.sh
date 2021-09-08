#!/bin/bash

source ./_workshop-config.lib

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
SETUP_TYPE=$1

MONACO_PROJECT_BASE_PATH=./monaco-files/projects
MONACO_ENVIONMENT_FILE=./monaco-files/environments.yaml

download_monaco() {
    if [ $(uname -s) == "Darwin" ]
    then
        MONACO_BINARY="v1.6.0/monaco-darwin-10.12-amd64"
    else
        MONACO_BINARY="v1.6.0/monaco-linux-amd64"
    fi
    echo "Getting MONACO_BINARY = $MONACO_BINARY"
    rm -f monaco
    wget -q -O monaco https://github.com/dynatrace-oss/dynatrace-monitoring-as-code/releases/download/$MONACO_BINARY
    chmod +x monaco
    echo "Installed monaco version: $(./monaco --version | tail -1)"
}

run_monaco() {
    if [ -z "$1" ]; then
        MONACO_PROJECT=workshop
    else
        MONACO_PROJECT=$1
    fi

    echo "Running monaco for project = $MONACO_PROJECT"
    echo "monaco deploy -v --environments $MONACO_ENVIONMENT_FILE --project $MONACO_PROJECT $MONACO_PROJECT_BASE_PATH"

    # add the --dry-run argument during testing
    export NEW_CLI=1 && export DT_BASEURL=$DT_BASEURL && export DT_API_TOKEN=$DT_API_TOKEN && \
        ./monaco deploy -v \
        --environments $MONACO_ENVIONMENT_FILE \
        --project $MONACO_PROJECT \
        $MONACO_PROJECT_BASE_PATH
}

run_custom_dynatrace_config() {
    setFrequentIssueDetectionOff
    setServiceAnomalyDetection ./custom/service-anomalydetection.json
}

echo ""
echo "-----------------------------------------------------------------------------------"
echo "Setting up Workshop config"
echo "Dynatrace  : $DT_BASEURL"
echo "Starting   : $(date)"
echo "-----------------------------------------------------------------------------------"
echo ""

case "$SETUP_TYPE" in
    "k8") 
        echo "Setup type = k8"
        download_monaco
        run_monaco k8
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        sleep 10
        run_monaco k8
        ;;
    "services-vm") 
        echo "Setup type = services-vm"
        download_monaco
        run_monaco services-vm
        ;;
    "synthetics") 
        echo "Setup type = synthetics"
        run_monaco synthetics
        ;;
    *)
        echo "Setup type = base workshop"
        download_monaco
        run_monaco
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        sleep 10
        run_monaco
        run_custom_dynatrace_config
        ;;
esac
 
echo ""
echo "-----------------------------------------------------------------------------------"
echo "Done Setting up Workshop config"
echo "End: $(date)"
echo "-----------------------------------------------------------------------------------"
