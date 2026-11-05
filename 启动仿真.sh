#!/usr/bin/env bash
# 启动 RMUL2027 哨兵仿真（深北莫 rmu_gazebo_simulator + RMUL2027 场地）
set -e

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="rmul2027_sentry_sim:1.0"
TAR="$HERE/images/rmul2027_sentry_sim_image.tar.gz"
NAME="rmul2027_sim"

# 有 docker 权限就直接用，否则用 sudo
DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

# 首次运行：优先导入离线镜像包，没有就从源码构建
if ! $DOCKER image inspect "$IMAGE" >/dev/null 2>&1; then
    if [[ -f "$TAR" ]]; then
        echo "首次运行，正在导入仿真镜像（约 1.1 GB，需要几分钟）..."
        $DOCKER load -i "$TAR"
    else
        BASE="${BASE_IMAGE:-ghcr.io/smbu-polarbear-robotics-team/rmu_gazebo_simulator:1.0.0}"
        echo "本地没有镜像，开始构建（首次需要拉取约 1 GB 基础镜像）..."
        echo "基础镜像: $BASE"
        if ! $DOCKER build --build-arg "BASE_IMAGE=$BASE" -t "$IMAGE" "$HERE/docker"; then
            echo "构建失败，改用南京大学 ghcr 镜像重试..."
            $DOCKER build \
                --build-arg "BASE_IMAGE=ghcr.nju.edu.cn/smbu-polarbear-robotics-team/rmu_gazebo_simulator:1.0.0" \
                -t "$IMAGE" "$HERE/docker"
        fi
    fi
fi

# 允许容器访问当前 X11 显示
if command -v xhost >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    xhost +local:root >/dev/null 2>&1 || true
fi

# GPU / 软件渲染
GPU_ARGS=()
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1 \
   && $DOCKER info 2>/dev/null | grep -q 'Runtimes:.*nvidia'; then
    GPU_ARGS=(--gpus all -e NVIDIA_DRIVER_CAPABILITIES=all)
    echo "检测到 NVIDIA 显卡，使用 GPU 渲染。"
else
    echo "未检测到可用的 NVIDIA 容器运行时，使用软件渲染（帧率会低一些）。"
    GPU_ARGS=(-e LIBGL_ALWAYS_SOFTWARE=1 -e GALLIUM_DRIVER=llvmpipe)
fi

$DOCKER rm -f "$NAME" >/dev/null 2>&1 || true

$DOCKER run -d --name "$NAME" \
    --network host --ipc=host \
    "${GPU_ARGS[@]}" \
    -e "DISPLAY=${DISPLAY:-:0}" \
    -e RCUTILS_COLORIZED_OUTPUT=0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    "$IMAGE" >/dev/null

echo
echo "仿真已启动（容器: $NAME）。"
echo "  - Gazebo 窗口应已弹出；首次加载约 5~10 秒。"
echo "  - 脚本会自动发送自检/开始比赛指令（START_SELF_CHECKING -> START_GAME）。"
echo "  - 查看日志:   $DOCKER logs -f $NAME"
echo "  - 进入终端:   ./进入终端.sh"
echo "  - 停止仿真:   ./停止.sh"
echo
echo "机器人话题命名空间: /red_standard_robot1"
echo "键盘/程序控制: 向 /red_standard_robot1/cmd_vel 发布 geometry_msgs/msg/Twist"
