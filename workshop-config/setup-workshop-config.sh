#!/bin/bash

source ./_workshop-config.lib

MONACO_PROJECT_BASE_PATH=./monaco/projects
MONACO_PROJECT=workshop
MONACO_ENVIONMENT_FILE=./monaco/environments.yaml
MONACO_CONFIG_FOLDER="$MONACO_PROJECT_BASE_PATH/$MONACO_PROJECT"

download_monaco() {
    if [ $(uname -s) == "Darwin" ]
    then
        MONACO_BINARY="v1.5.0/monaco-darwin-10.6-amd64"
    else
        MONACO_BINARY="v1.5.0/monaco-linux-amd64"
    fi
    echo "Getting MONACO_BINARY = $MONACO_BINARY"
    rm -f monaco-binary
    wget -q -O monaco-binary https://github.com/dynatrace-oss/dynatrace-monitoring-as-code/releases/download/$MONACO_BINARY
    chmod +x monaco-binary
    echo "Installed monaco version: $(./monaco-binary --version)"
}

run_monaco() {
    # run monaco configuration
    # add the -dry-run argument to test
    export NEW_CLI=1
    export DT_BASEURL=$DT_BASEURL && export DT_API_TOKEN=$DT_API_TOKEN && ./monaco-binary deploy -v --environments $MONACO_ENVIONMENT_FILE --project $MONACO_PROJECT $MONACO_PROJECT_BASE_PATH
}

run_custom_dynatrace_config() {
    setFrequentIssueDetectionOff
    setServiceAnomalyDetection ./custom/service-anomalydetection.json
}

echo ""
echo "-----------------------------------------------------------------------------------"
echo "Setting up Workshop config on $DT_BASEURL"
echo "Starting: $(date)"
echo "-----------------------------------------------------------------------------------"

download_monaco
run_monaco
run_custom_dynatrace_config

echo ""
echo "-----------------------------------------------------------------------------------"
echo "Done Setting up Workshop config"
echo "End: $(date)"
echo "-----------------------------------------------------------------------------------"
