#!/bin/sh

docker image build \
    --build-arg USER_ID=$(id -u ${USER}) \
    --build-arg GROUP_ID=$(id -g ${USER}) \
    --build-arg IP_ADDRESS=$(ip a | grep docker0 | grep inet | awk '{print $2}' | awk -F'/' '{print $1}') \
    -t docker.local.com/php:70 \
    .
