#!/bin/bash

source ./_workshop-config.lib

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
SETUP_TYPE=$1
DASHBOARD_OWNER_EMAIL=$2    # This is required for the dashboard monaco project
                            # Otherwise it is not required

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
    MONACO_PROJECT=$1
    DASHBOARD_OWNER=$2

    if [ -z $MONACO_PROJECT ]; then
        echo "ERROR: run_monaco() Missing MONACO_PROJECT argument"
        exit 1
    fi

    if [ -z $DASHBOARD_OWNER ]; then
        # need to do this so that the monaco valdiation does not fail
        # even though you are not running the dashboard project, monaco
        # still valdiates all the projects in the projects folders 
        export OWNER=DUMMY_PLACEHOLDER
    else
        export OWNER=$DASHBOARD_OWNER_EMAIL
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
    "cluster") 
        echo "Setup type = cluster"
        download_monaco
        run_monaco cluster
        echo "-----------------------------------------------------------------------------------"
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        echo "-----------------------------------------------------------------------------------"
        sleep 10
        run_monaco cluster
        ;;
    "services-vm") 
        echo "Setup type = services-vm"
        download_monaco
        run_monaco services-vm
        echo "-----------------------------------------------------------------------------------"
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        echo "-----------------------------------------------------------------------------------"
        sleep 10
        run_monaco services-vm
        run_custom_dynatrace_config
        ;;
    "synthetics") 
        echo "Setup type = synthetics"
        run_monaco synthetics
        ;;
    "dashboard") 
        if [ -z $DASHBOARD_OWNER_EMAIL ]; then
            echo "ABORT dashboard owner email is required argument"
            echo "syntax: ./setup-workshop-config.sh dashboard name@company.com"
            exit 1
        else
            echo "Setup type = dashboard"
            run_monaco db $DASHBOARD_OWNER_EMAIL
        fi
        ;;
    "monolith-vm")
        echo "Setup type = monolith-vm"
        download_monaco
        run_monaco monolith-vm
        echo "-----------------------------------------------------------------------------------"
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        echo "-----------------------------------------------------------------------------------"
        sleep 10
        run_monaco monolith-vm
        run_custom_dynatrace_config
        ;;
    *)
        echo ""
        echo "-----------------------------------------------------------------------------------"
        echo "ERROR: Missing or invalid SETUP_TYPE argument"
        echo "Valid values are: monolith-vm, services-vm, cluster, dashboard"
        echo ""
        exit 1
        ;;
esac
 
echo ""
echo "-----------------------------------------------------------------------------------"
echo "Done Setting up Workshop config"
echo "End: $(date)"
echo "-----------------------------------------------------------------------------------"
