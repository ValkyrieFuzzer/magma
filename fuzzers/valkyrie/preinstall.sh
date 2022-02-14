#!/bin/bash
set -ex

apt-get update && \
    apt-get install -y make build-essential cmake git golang-go \
    python-pip python-dev wget zlib1g-dev

# Install Python packages
pip install --upgrade pip==9.0.3
pip install wllvm
