# Andean HydroMet Sentinel

Andean HydroMet Sentinel is a Tethys Platform app prototype for the Tethys
Summit 2026 App Development Contest. It turns INAMHI station observations and
ECMWF open-data forecasts into a station-calibrated hydro-meteorological
dashboard for Quito's Inaquito station.

The first workflow focuses on temperature because ECMWF 2 m temperature
products are reliable to fetch and verify quickly. The app also preserves
INAMHI precipitation, humidity, pressure, and radiation observations so the
dashboard can grow into a broader hydrology and meteorology decision-support
tool.

## What it does

- Fetches INAMHI hourly observations for station `63777` (`Inaquito`).
- Retrieves ECMWF open-data temperature forecasts for the nearest model grid
  point.
- Applies a local bias correction using recent station observations and
  archived forecast verification.
- Archives each forecast run and scores later forecasts against observed
  station data.
- Displays a Tethys dashboard with station context, current forecast,
  verification metrics, and a contest-ready open-source workflow.
- Falls back to deterministic demo data when live data dependencies or network
  access are unavailable.

## One-Shot Contest Install

From a fresh clone:

```bash
git clone https://github.com/ccardenas93/tethys_app.git
cd tethys_app
./scripts/bootstrap.sh
./scripts/start_server.sh
```

Prerequisite: a working `conda` installation, such as Miniforge or Mambaforge.

Open:

```text
http://127.0.0.1:8000/apps/andean-hydromet/
```

Default local login:

```text
username: admin
password: pass
```

The bootstrap script creates or reuses the `tethys-contest` conda environment,
installs the app in editable mode, creates a repo-local Tethys home at
`.tethys_home`, initializes the SQLite portal database, registers the Tethys
app, and generates demo forecast artifacts so the dashboard opens immediately.

Use live data during setup:

```bash
./scripts/bootstrap.sh --live
```

Install and start in one command:

```bash
./scripts/bootstrap.sh --start
```

Useful overrides:

```bash
CONDA_ENV_NAME=hydromet-demo ./scripts/bootstrap.sh
TETHYS_HOME="$HOME/.tethys/andean-hydromet" ./scripts/bootstrap.sh
PORT=8010 ./scripts/bootstrap.sh --start
```

Make shortcuts:

```bash
make install
make start
make demo
make live
make test
```

## Offline Smoke Test

The core pipeline can be tested without Tethys:

```bash
conda run --no-capture-output -n tethys-contest python -m pytest tests
```

Or generate deterministic demo artifacts:

```bash
./scripts/run_live_forecast.sh --demo
```

## Live Data Notes

The live workflow uses:

- INAMHI hourly station API: `https://inamhi.gob.ec/api_rest/station_data_hour/get_data_hour/`
- ECMWF Open Data through `ecmwf-opendata`
- GRIB decoding through `cfgrib` and `eccodes`

The app does not store API secrets. The first live run may take time because it
downloads GRIB data and builds the forecast archive.

## Make It Live

The Tethys dashboard should read cached forecast artifacts quickly. A scheduled
job should refresh those artifacts hourly, matching the original
`ccardenas93/weather_forecast` GitHub Actions pattern.

Manual live refresh:

```bash
./scripts/run_live_forecast.sh
```

Run the portal:

```bash
./scripts/start_server.sh
```

During development from a Terminal session, use the foreground loop:

```bash
./scripts/run_forever_hourly.sh
```

Or send it to the background:

```bash
mkdir -p logs
nohup ./scripts/run_forever_hourly.sh > logs/hourly-loop.log 2>&1 &
echo $! > logs/hourly-loop.pid
```

Stop the background loop:

```bash
kill "$(cat logs/hourly-loop.pid)"
```

Install the optional macOS launchd hourly job:

```bash
./scripts/install_launchd.sh
```

The wrappers write daily logs to `logs/forecast-YYYYMMDD.log` and skip a run if
the previous ECMWF download is still active. Keep the Tethys dev server running;
the scheduler only refreshes cached artifacts that the dashboard reads. If
launchd reports `Operation not permitted` for an external volume, use the
Terminal loop or move the project under your home directory before installing
the LaunchAgent.

For production, wire the same command into a server scheduler, GitHub Actions,
or a Tethys scheduler task. Avoid fetching ECMWF directly in the page request
path; user requests should render the latest cached result.

## Contest Direction

The contest version should add at least one hydrology-facing workflow before
June 2026:

- precipitation event context from INAMHI station observations,
- flood/heat compound-risk summaries,
- a second nearby station comparison,
- or a catchment-level layer if a public Ecuador basin dataset is selected.

Keep the repo open source, document data sources, and record AI assistance in
`AI_USE.md`.
