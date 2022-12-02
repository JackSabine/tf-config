#!/bin/bash

# Bash unofficial strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TF2CFG_DIR="/home/${USER}/.steam/debian-installation/steamapps/common/Team Fortress 2/tf/cfg"

stow -t "${TF2CFG_DIR}" -d "${SCRIPT_DIR}" .
