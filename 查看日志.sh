#!/usr/bin/env bash
# 跟踪日志
set -e

DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

NAME="${1:-rmul2027_sim}"
exec $DOCKER logs -f --tail=80 "$NAME"
