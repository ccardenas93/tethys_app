#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/logs"
LOCK_DIR="${ROOT_DIR}/.hourly_forecast.lock"
LOG_FILE="${LOG_DIR}/forecast-$(date -u +%Y%m%d).log"

mkdir -p "${LOG_DIR}"

if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
  {
    echo "==== $(date -u '+%Y-%m-%dT%H:%M:%SZ') skipped: previous run still active ===="
  } >> "${LOG_FILE}" 2>&1
  exit 0
fi

cleanup() {
  rmdir "${LOCK_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

{
  echo "==== $(date -u '+%Y-%m-%dT%H:%M:%SZ') starting hourly forecast ===="
  "${ROOT_DIR}/scripts/run_live_forecast.sh"
  echo "==== $(date -u '+%Y-%m-%dT%H:%M:%SZ') completed hourly forecast ===="
  echo
} >> "${LOG_FILE}" 2>&1
