import json

import pandas as pd

from tethysapp.andean_hydromet.services.forecast_pipeline import (
    artifact_paths,
    generate_demo_observations,
    load_station_targets,
    run_pipeline,
    run_self_test,
)


def test_self_test_passes():
    assert run_self_test() == "passed"


def test_demo_observations_include_required_targets(tmp_path):
    run_time = pd.Timestamp("2026-04-12T12:00:00Z")
    observations = generate_demo_observations(run_time, periods=48)
    raw_path = tmp_path / "observations.csv"
    observations.to_csv(raw_path, index=False)

    station_targets = load_station_targets(raw_path)

    assert {"observed_max_c", "observed_prom_c", "observed_min_c"}.issubset(station_targets.columns)
    assert station_targets.notna().any().all()


def test_demo_pipeline_writes_dashboard_artifacts(tmp_path):
    summary = run_pipeline(tmp_path, demo=True)
    paths = artifact_paths(tmp_path)

    assert summary["mode"] == "demo"
    assert paths["forecast_csv"].exists()
    assert paths["forecast_html"].exists()
    assert paths["forecast_archive"].exists()
    assert paths["forecast_metrics"].exists()
    assert paths["dashboard_summary"].exists()

    persisted = json.loads(paths["dashboard_summary"].read_text(encoding="utf-8"))
    assert persisted["station"]["name"] == "Inaquito"
    assert persisted["risk"]["level"] in {"normal", "watch", "elevated"}
    assert persisted["artifact_counts"]["archive_rows"] > 0
