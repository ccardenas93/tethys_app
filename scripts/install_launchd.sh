#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TETHYS_HOME="${TETHYS_HOME:-${ROOT_DIR}/.tethys_home}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-tethys-contest}"
LABEL="com.andean-hydromet.forecast"
TEMPLATE="${ROOT_DIR}/launchd/${LABEL}.plist.template"
AGENT_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"

mkdir -p "${HOME}/Library/LaunchAgents" "${ROOT_DIR}/logs"

sed \
  -e "s|__ROOT_DIR__|${ROOT_DIR}|g" \
  -e "s|__TETHYS_HOME__|${TETHYS_HOME}|g" \
  -e "s|__CONDA_ENV_NAME__|${CONDA_ENV_NAME}|g" \
  "${TEMPLATE}" > "${AGENT_PATH}"

launchctl bootout "gui/$(id -u)" "${AGENT_PATH}" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "${AGENT_PATH}"
launchctl kickstart -k "gui/$(id -u)/${LABEL}"
launchctl print "gui/$(id -u)/${LABEL}"
