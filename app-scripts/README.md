# Overview

These scripts stop and start the dt-orders application in both monolith and services mode.

# Prerequisites

1. This repo was git cloned to `/home/ubuntu/aws-modernization-dt-orders-setup`

1. The VM running Docker and has Docker-Compose installed

# Usage

1. Monolith version
    * The `start-monolith.sh` will call the `stop-monolith.sh` first, then it will start the application.
    * A startup log is written to `/tmp/start-monolith.log`
    * App runs on port 80

1. Services version
    * The `start-services.sh` will call the `stop-services.sh` first, then it will start the application.
    * A startup log is written to `/tmp/start-services.log`
    * App runs on port 80
