ARG BASE_IMAGE=ghcr.io/smbu-polarbear-robotics-team/rmu_gazebo_simulator:1.0.0
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="RMUL2027 Sentry Simulation"
LABEL org.opencontainers.image.description="SMBU PolarBear rmu_gazebo_simulator + RMUL 2027 3v3 field"

# --- Add the RMUL 2027 field model -------------------------------------------
COPY models/rmul2027_field \
     /root/ros_ws/src/rmu_gazebo_simulator/rmu_gazebo_simulator/resource/models/rmul2027_field

# --- Add the RMUL 2027 world -------------------------------------------------
COPY worlds/rmul_2027_world.sdf \
     /root/ros_ws/src/rmu_gazebo_simulator/rmu_gazebo_simulator/resource/worlds/rmul_2027_world.sdf

# --- Select the new world and add spawn poses --------------------------------
COPY config/gz_world.yaml \
     /root/ros_ws/src/rmu_gazebo_simulator/rmu_gazebo_simulator/config/gz_world.yaml

# --- Auto-start launch + better GUI camera for the smaller field -------------
COPY bringup_rmul2027.launch.py \
     /root/ros_ws/src/rmu_gazebo_simulator/rmu_gazebo_simulator/launch/bringup_rmul2027.launch.py
COPY gui.config \
     /root/ros_ws/src/rmu_gazebo_simulator/rmu_gazebo_simulator/resource/ign/gui.config

# --- Reinstall the (resource-only) package -----------------------------------
RUN . /opt/ros/humble/setup.sh && \
    rm -rf /root/ros_ws/build/rmu_gazebo_simulator /root/ros_ws/install/rmu_gazebo_simulator && \
    cd /root/ros_ws && \
    colcon build --packages-select rmu_gazebo_simulator \
        --cmake-args -DCMAKE_BUILD_TYPE=release && \
    rm -rf /root/ros_ws/build/rmu_gazebo_simulator /root/ros_ws/log

# Convenience entrypoint for the simulator
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
CMD ["ros2", "launch", "rmu_gazebo_simulator", "bringup_rmul2027.launch.py"]
