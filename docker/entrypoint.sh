#!/usr/bin/env bash
set -e

source /opt/ros/humble/setup.bash
source /root/ros_ws/install/setup.bash

# Helpful defaults (can be overridden with -e)
export RCUTILS_COLORIZED_OUTPUT=${RCUTILS_COLORIZED_OUTPUT:-1}
export IGN_GAZEBO_RESOURCE_PATH=${IGN_GAZEBO_RESOURCE_PATH:-/root/ros_ws/install/rmu_gazebo_simulator/share/rmu_gazebo_simulator/resource}

exec "$@"
