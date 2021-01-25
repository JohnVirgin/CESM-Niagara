#!/bin/sh

./xmlchange STOP_N="1"
./xmlchange STOP_OPTION="nmonths"

./xmlchange --append --file env_build.xml --id CAM_CONFIG_OPTS --val="-nlev=26"
