#!/usr/bin/env bash
# 一键启动：仿真 + 导航栈
set -e

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$HERE/启动仿真.sh"
echo "等待仿真和机器人加载（12 秒）..."
sleep 12
"$HERE/启动导航.sh"
