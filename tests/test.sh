#!/bin/bash

set -euo pipefail

. /bin/docker-functions.sh

start_docker
await_docker

docker run hello-world
