#!/bin/bash

SERVICE=$1
NEW_VERSION=$2

source ./_learner-scripts.lib
setServicesVersion $SERVICE $NEW_VERSION
