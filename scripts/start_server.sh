#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TETHYS_HOME="${TETHYS_HOME:-${ROOT_DIR}/.tethys_home}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-tethys-contest}"
PORT="${PORT:-8000}"
CONDA_BIN="${CONDA_EXE:-}"

if [[ -z "${CONDA_BIN}" ]]; then
  if command -v conda >/dev/null 2>&1; then
    CONDA_BIN="$(command -v conda)"
  else
    echo "Could not find conda. Set CONDA_EXE or add conda to PATH." >&2
    exit 127
  fi
fi

cd "${ROOT_DIR}"

exec env TETHYS_HOME="${TETHYS_HOME}" \
  "${CONDA_BIN}" run --no-capture-output -n "${CONDA_ENV_NAME}" \
  tethys start -p "${PORT}"
