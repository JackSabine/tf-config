#!/bin/bash

# Bash unofficial strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TF_DIR="/home/${USER}/.steam/debian-installation/steamapps/common/Team Fortress 2/tf/"

stow -t "${TF_DIR}" -d "${SCRIPT_DIR}" .
