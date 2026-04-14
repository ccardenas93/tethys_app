#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-tethys-contest}"
TETHYS_HOME="${TETHYS_HOME:-${ROOT_DIR}/.tethys_home}"
PORT="${PORT:-8000}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-pass}"

SKIP_ENV=0
UPDATE_ENV=0
GENERATE_ARTIFACTS=1
ARTIFACT_MODE="demo"
START_SERVER=0

usage() {
  cat <<USAGE
Usage: ./scripts/bootstrap.sh [options]

One-shot local setup for Andean HydroMet Sentinel.

Options:
  --skip-env      Do not create or update the conda environment.
  --update-env    Update an existing conda environment from environment.yml.
  --no-demo       Do not generate initial forecast artifacts.
  --live          Generate initial live artifacts instead of demo artifacts.
  --start         Start the Tethys server after install.
  --port PORT     Server port for --start. Default: ${PORT}.
  -h, --help      Show this help.

Environment:
  CONDA_ENV_NAME  Conda environment name. Default: ${CONDA_ENV_NAME}.
  TETHYS_HOME     Tethys home directory. Default: ${TETHYS_HOME}.
  ADMIN_USERNAME  Initial admin username. Default: ${ADMIN_USERNAME}.
  ADMIN_PASSWORD  Initial admin password. Default: ${ADMIN_PASSWORD}.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-env)
      SKIP_ENV=1
      ;;
    --update-env)
      UPDATE_ENV=1
      ;;
    --no-demo)
      GENERATE_ARTIFACTS=0
      ;;
    --live)
      ARTIFACT_MODE="live"
      ;;
    --start)
      START_SERVER=1
      ;;
    --port)
      PORT="${2:?Missing value for --port}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

find_conda() {
  if [[ -n "${CONDA_EXE:-}" ]]; then
    printf '%s\n' "${CONDA_EXE}"
  elif command -v conda >/dev/null 2>&1; then
    command -v conda
  else
    return 1
  fi
}

CONDA_BIN="$(find_conda)" || {
  echo "Could not find conda. Install Miniforge/Mambaforge or set CONDA_EXE." >&2
  exit 127
}

conda_env_exists() {
  "${CONDA_BIN}" env list | awk '{print $1}' | grep -Fxq "${CONDA_ENV_NAME}"
}

run_in_env() {
  env TETHYS_HOME="${TETHYS_HOME}" \
    "${CONDA_BIN}" run --no-capture-output -n "${CONDA_ENV_NAME}" "$@"
}

cd "${ROOT_DIR}"

echo "== Andean HydroMet Sentinel bootstrap =="
echo "Repository: ${ROOT_DIR}"
echo "TETHYS_HOME: ${TETHYS_HOME}"
echo "Conda environment: ${CONDA_ENV_NAME}"

if [[ "${SKIP_ENV}" -eq 0 ]]; then
  if conda_env_exists; then
    if [[ "${UPDATE_ENV}" -eq 1 ]]; then
      echo "== Updating conda environment =="
      "${CONDA_BIN}" env update -n "${CONDA_ENV_NAME}" -f "${ROOT_DIR}/environment.yml" --prune
    else
      echo "== Conda environment exists; skipping dependency solve =="
      echo "   Use --update-env if dependencies changed."
    fi
  else
    echo "== Creating conda environment =="
    "${CONDA_BIN}" env create -n "${CONDA_ENV_NAME}" -f "${ROOT_DIR}/environment.yml"
  fi
else
  echo "== Skipping conda environment step =="
fi

echo "== Installing app package in editable mode =="
run_in_env python -m pip install --no-build-isolation --no-deps -e "${ROOT_DIR}"

mkdir -p "${TETHYS_HOME}"
if [[ ! -f "${TETHYS_HOME}/portal_config.yml" ]]; then
  echo "== Generating Tethys portal config =="
  run_in_env tethys gen portal_config --overwrite -d "${TETHYS_HOME}"
else
  echo "== Tethys portal config already exists =="
fi

if [[ ! -f "${TETHYS_HOME}/tethys_platform.sqlite" ]]; then
  echo "== Initializing Tethys database and admin user =="
  run_in_env tethys db configure \
    --portal-superuser-name "${ADMIN_USERNAME}" \
    --portal-superuser-email "${ADMIN_EMAIL}" \
    --portal-superuser-password "${ADMIN_PASSWORD}" \
    -y
else
  echo "== Migrating existing Tethys database =="
  run_in_env tethys db migrate
fi

echo "== Registering Tethys app =="
run_in_env tethys install -d -q -w

if [[ "${GENERATE_ARTIFACTS}" -eq 1 ]]; then
  if [[ "${ARTIFACT_MODE}" == "live" ]]; then
    echo "== Generating initial live artifacts =="
    "${ROOT_DIR}/scripts/run_live_forecast.sh"
  else
    echo "== Generating initial demo artifacts =="
    "${ROOT_DIR}/scripts/run_live_forecast.sh" --demo
  fi
fi

echo "== Installed app URLs =="
run_in_env tethys list --urls

cat <<DONE

Setup complete.

Open:
  http://127.0.0.1:${PORT}/apps/andean-hydromet/

Login:
  username: ${ADMIN_USERNAME}
  password: ${ADMIN_PASSWORD}

Start the portal:
  TETHYS_HOME="${TETHYS_HOME}" CONDA_ENV_NAME="${CONDA_ENV_NAME}" PORT="${PORT}" ./scripts/start_server.sh

Refresh live forecast once:
  TETHYS_HOME="${TETHYS_HOME}" CONDA_ENV_NAME="${CONDA_ENV_NAME}" ./scripts/run_live_forecast.sh

Run hourly forecast loop:
  TETHYS_HOME="${TETHYS_HOME}" CONDA_ENV_NAME="${CONDA_ENV_NAME}" ./scripts/run_forever_hourly.sh
DONE

if [[ "${START_SERVER}" -eq 1 ]]; then
  echo
  echo "== Starting Tethys server =="
  TETHYS_HOME="${TETHYS_HOME}" CONDA_ENV_NAME="${CONDA_ENV_NAME}" PORT="${PORT}" \
    "${ROOT_DIR}/scripts/start_server.sh"
fi
