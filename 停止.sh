#!/usr/bin/env bash
# 停止仿真 / 导航容器
set -e

DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

for name in rmul2027_nav rmul2027_sim; do
    if $DOCKER ps -a --format '{{.Names}}' | grep -qx "$name"; then
        $DOCKER rm -f "$name" >/dev/null
        echo "已停止 $name"
    fi
done
