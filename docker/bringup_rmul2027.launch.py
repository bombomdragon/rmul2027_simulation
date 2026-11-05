# Copyright 2026
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Bring up the RMUL 2027 field and start a match automatically.

Difference from ``bringup_sim.launch.py``: after Gazebo and the robot have
finished loading, this launch file

1. unpauses the Ignition world (if it started paused), and
2. sends ``START_SELF_CHECKING`` + ``START_GAME`` referee commands,

so the sentry / behavior tree can be tested without clicking through the
web referee UI.
"""

import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.conditions import IfCondition
from launch.actions import (
    DeclareLaunchArgument,
    ExecuteProcess,
    IncludeLaunchDescription,
    TimerAction,
)
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration


def generate_launch_description():
    pkg_simulator = get_package_share_directory("rmu_gazebo_simulator")

    auto_start = LaunchConfiguration("auto_start")
    startup_delay = LaunchConfiguration("startup_delay")

    declare_auto_start = DeclareLaunchArgument(
        "auto_start",
        default_value="true",
        description="Unpause the world and send START_GAME automatically",
    )
    declare_startup_delay = DeclareLaunchArgument(
        "startup_delay",
        default_value="8.0",
        description="Seconds to wait for Gazebo + robot spawn before starting",
    )

    bringup_sim = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_simulator, "launch", "bringup_sim.launch.py")
        )
    )

    # One shell process: unpause the world, then start the match through the
    # referee system (SELF_CHECKING -> START_GAME).
    start_match = ExecuteProcess(
        cmd=[
            "bash",
            "-c",
            (
                "ign service -s /world/default/control "
                "--reqtype ignition.msgs.WorldControl "
                "--reptype ignition.msgs.Boolean --timeout 3000 "
                "--req 'pause: false' >/dev/null 2>&1; "
                "sleep 1; "
                "ros2 topic pub --once /referee_system/referee_cmd "
                "rmoss_interfaces/msg/RefereeCmd '{cmd: 1}' >/dev/null 2>&1; "
                "sleep 1; "
                "ros2 topic pub --once /referee_system/referee_cmd "
                "rmoss_interfaces/msg/RefereeCmd '{cmd: 2}' >/dev/null 2>&1"
            ),
        ],
        output="screen",
        condition=IfCondition(auto_start),
    )

    ld = LaunchDescription()
    ld.add_action(declare_auto_start)
    ld.add_action(declare_startup_delay)
    ld.add_action(bringup_sim)
    ld.add_action(TimerAction(period=startup_delay, actions=[start_match]))
    return ld
