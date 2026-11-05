#!/usr/bin/env bash
# 启动深北莫 pb2025_sentry_nav 导航栈（Nav2 + point_lio + slam_toolbox）
# 需要先运行 ./启动仿真.sh
set -e

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="ghcr.io/smbu-polarbear-robotics-team/pb2025_sentry_nav:1.3.2"
TAR="$HERE/images/pb2025_sentry_nav_image.tar.gz"
NAME="rmul2027_nav"
RVIZ="${RVIZ:-false}"

DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

if ! $DOCKER ps --format '{{.Names}}' | grep -qx "rmul2027_sim"; then
    echo "仿真还没启动，请先执行 ./启动仿真.sh" >&2
    exit 1
fi

if ! $DOCKER image inspect "$IMAGE" >/dev/null 2>&1; then
    if [[ -f "$TAR" ]]; then
        echo "首次运行，正在导入导航镜像（约 1.7 GB，需要几分钟）..."
        $DOCKER load -i "$TAR"
    else
        echo "本地没有导航镜像，尝试拉取..."
        if ! $DOCKER pull "$IMAGE"; then
            echo "直连 ghcr.io 失败，改用南京大学镜像..."
            $DOCKER pull ghcr.nju.edu.cn/smbu-polarbear-robotics-team/pb2025_sentry_nav:1.3.2
            $DOCKER tag ghcr.nju.edu.cn/smbu-polarbear-robotics-team/pb2025_sentry_nav:1.3.2 "$IMAGE"
        fi
    fi
fi

if command -v xhost >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    xhost +local:root >/dev/null 2>&1 || true
fi

$DOCKER rm -f "$NAME" >/dev/null 2>&1 || true

echo "启动导航栈（SLAM 模式，无需先验点云；首次建图需要机器人先动起来）..."
$DOCKER run -d --name "$NAME" \
    --network host --ipc=host \
    -e "DISPLAY=${DISPLAY:-:0}" \
    -e RCUTILS_COLORIZED_OUTPUT=0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    --entrypoint bash \
    "$IMAGE" -lc "source /opt/ros/humble/setup.bash; \
source /root/ros_ws/install/setup.bash; \
exec ros2 launch pb2025_nav_bringup rm_navigation_simulation_launch.py \
    namespace:=red_standard_robot1 \
    slam:=True \
    use_rviz:=$RVIZ \
    use_sim_time:=True" >/dev/null

cat <<EOF

导航栈已启动（容器: $NAME）。
  - 等待约 10 秒，Nav2 生命周期节点会自动激活。
  - 发送目标点（在容器里）：
      ./进入终端.sh $NAME
      ros2 action send_goal /red_standard_robot1/navigate_to_pose \\
        nav2_msgs/action/NavigateToPose \\
        "{pose: {header: {frame_id: map}, pose: {position: {x: 2.0, y: 0.0}, orientation: {w: 1.0}}}}"
  - 行为树接的是 Nav2 action: /red_standard_robot1/navigate_to_pose
  - 查看日志: $DOCKER logs -f $NAME
  - 需要 RViz 时: RVIZ=true ./启动导航.sh
EOF
