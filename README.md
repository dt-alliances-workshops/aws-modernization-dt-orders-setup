# Overview

The repo contains the setup and learner scripts to support [this AWS and Dynatrace workshop](http://aws-modernize-workshop.alliances.dynatracelabs.com/).

<img src="dt-aws.png" width="400"/> 

A learner generally would not run any scripts within this repo.  The scripts and files used by the [Dynatrace Training University (DTU)](https://university.dynatrace.com)) provisioning scripts that pre-provision the workshop for each learner.

# Repo Structure

1. `provision-scripts/` - Scripts related to installing any prerequisite software
1. `app-scripts/` - Scripts related to installing workshop sample applications.
1. `workshop-config/` -Scripts related to the setup of the Dynatrace configuration for the learners Dynatrace tenant.
1. `learner-scripts/` - Scripts that get copied for learner to use in workshop labs.

See the README files in the subfolders for additional details.

# Prerequisites

The various scripts assume the learners unique credentials are stored in this file within this folder.

`/home/dtu_training/workshop-credentials.json`

The expected format as follows:

```
{
    "LAB_NAME": "RESOURCE_PREFIX_PLACEHOLDER",
    "DT_BASEURL": "DT_BASEURL_PLACEHOLDER",
    "DT_PAAS_TOKEN": "DT_PAAS_TOKEN_PLACEHOLDER",
    "DT_API_TOKEN": "DT_API_TOKEN_PLACEHOLDER"
}
```
Notes:
* `LAB_NAME` is value of `MONOLITH` or `SERVICES`
* `DT_BASEURL` is format such as `https://xxxx.live.dynatrace.com`

# Feedback

Whether it's a bug report, new feature, correction, or additional documentation, we greatly value feedback and contributions.

You can share your feedback by opening a new issue [here](https://github.com/dt-alliances-workshops/aws-modernization-dt-orders-setup/issues).

Please ensure we have all the necessary information to effectively respond to your bug report or contribution such as:
* The URL to the page, file or script with an issue
* A reproducible test case or series of steps

# Maintainer

[Rob Jahn](https://www.linkedin.com/in/robjahn/) -- Email me @ rob.jahn@dynatrace.com with questions or more details.