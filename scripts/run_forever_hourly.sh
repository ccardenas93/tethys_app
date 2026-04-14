#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INTERVAL_SECONDS="${FORECAST_INTERVAL_SECONDS:-3600}"

cd "${ROOT_DIR}"

while true; do
  ./scripts/run_hourly_forecast.sh
  sleep "${INTERVAL_SECONDS}"
done
