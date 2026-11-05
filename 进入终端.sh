#!/usr/bin/env bash
# 在正在运行的仿真容器里开一个已 source 好 ROS 2 的终端
set -e

DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

NAME="${1:-rmul2027_sim}"

if ! $DOCKER ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "容器 $NAME 没有在运行，先执行 ./启动仿真.sh" >&2
    exit 1
fi

exec $DOCKER exec -it "$NAME" bash -lc '
    source /opt/ros/humble/setup.bash
    source /root/ros_ws/install/setup.bash
    echo "ROS 2 Humble 已就绪；工作空间: /root/ros_ws"
    echo "示例: ros2 topic list | grep red_standard_robot1"
    exec bash
'
