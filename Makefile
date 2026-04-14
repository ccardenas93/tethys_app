SHELL := /usr/bin/env bash

.PHONY: install install-live start demo live hourly launchd test

install:
	./scripts/bootstrap.sh

install-live:
	./scripts/bootstrap.sh --live

start:
	./scripts/start_server.sh

demo:
	./scripts/run_live_forecast.sh --demo

live:
	./scripts/run_live_forecast.sh

hourly:
	./scripts/run_forever_hourly.sh

launchd:
	./scripts/install_launchd.sh

test:
	conda run --no-capture-output -n $${CONDA_ENV_NAME:-tethys-contest} python -m pytest tests
