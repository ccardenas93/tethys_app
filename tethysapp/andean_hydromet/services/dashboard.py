"""Dashboard assembly helpers for Tethys controllers."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .forecast_pipeline import (
    DEFAULT_STATION,
    StationConfig,
    artifact_paths,
    ensure_demo_artifacts,
    run_pipeline,
)


def workspace_path(app_workspace: Any) -> Path:
    """Normalize Tethys path/workspace objects to pathlib.Path."""

    path = getattr(app_workspace, "path", app_workspace)
    return Path(path)


def load_dashboard_context(
    workspace: Path,
    station: StationConfig = DEFAULT_STATION,
    run_mode: str | None = None,
) -> dict[str, Any]:
    """Load or regenerate dashboard artifacts for the controller."""

    workspace = Path(workspace)
    paths = artifact_paths(workspace)
    refresh_error = None

    if run_mode == "demo":
        summary = run_pipeline(workspace, station=station, demo=True)
    elif run_mode == "live":
        try:
            summary = run_pipeline(workspace, station=station, demo=False)
        except Exception as exc:  # noqa: BLE001 - keep portal responsive during data outages.
            refresh_error = str(exc)
            summary = ensure_demo_artifacts(workspace, station=station)
    else:
        summary = ensure_demo_artifacts(workspace, station=station)

    if paths["dashboard_summary"].exists():
        summary = json.loads(paths["dashboard_summary"].read_text(encoding="utf-8"))

    forecast_html = read_text(paths["forecast_html"], "<p>No forecast panel has been generated yet.</p>")
    metrics_html = read_text(paths["metrics_html"], "<p>No metrics panel has been generated yet.</p>")
    status_md = read_text(paths["system_status"], "No system status has been generated yet.")

    station_payload = summary.get("station", station.__dict__)
    latest_forecast = summary.get("latest_forecast", {})
    weighted_metrics = summary.get("weighted_metrics", {})
    risk = summary.get("risk", {})

    return {
        "station": station_payload,
        "run_time": summary.get("run_time"),
        "mode": summary.get("mode", "demo"),
        "ecmwf_source": summary.get("ecmwf_source"),
        "latest_forecast": latest_forecast,
        "observation_context": summary.get("observation_context", {}),
        "risk": risk,
        "weighted_metrics": weighted_metrics,
        "target_metrics": summary.get("target_metrics", []),
        "artifact_counts": summary.get("artifact_counts", {}),
        "forecast_html": forecast_html,
        "metrics_html": metrics_html,
        "status_md": status_md,
        "refresh_error": refresh_error,
        "forecast_csv_path": str(paths["forecast_csv"]),
        "forecast_original_html_path": str(paths["forecast_original_html"]),
        "metrics_csv_path": str(paths["forecast_metrics"]),
        "archive_csv_path": str(paths["forecast_archive"]),
        "station_lat": station_payload.get("latitude"),
        "station_lon": station_payload.get("longitude"),
        "cards": build_cards(summary),
    }


def read_text(path: Path, fallback: str) -> str:
    if path.exists():
        return path.read_text(encoding="utf-8")
    return fallback


def build_cards(summary: dict[str, Any]) -> list[dict[str, str]]:
    latest_forecast = summary.get("latest_forecast", {})
    weighted_metrics = summary.get("weighted_metrics", {})
    observation_context = summary.get("observation_context", {})
    risk = summary.get("risk", {})

    return [
        {
            "label": "Mean Forecast",
            "value": celsius(latest_forecast.get("forecast_prom_c")),
            "detail": "next forecast valid time",
        },
        {
            "label": "HydroMet Level",
            "value": str(risk.get("level", "warming up")).title(),
            "detail": f"score {format_number(risk.get('score'), 2)}",
        },
        {
            "label": "24h Rain",
            "value": mm(observation_context.get("precip_24h_mm")),
            "detail": "INAMHI station observation",
        },
        {
            "label": "Forecast Skill",
            "value": celsius(weighted_metrics.get("forecast_mae_c")),
            "detail": "weighted verified MAE",
        },
    ]


def format_number(value: Any, digits: int = 1) -> str:
    if value is None:
        return "n/a"
    try:
        return f"{float(value):.{digits}f}"
    except (TypeError, ValueError):
        return "n/a"


def celsius(value: Any) -> str:
    formatted = format_number(value, 1)
    return "n/a" if formatted == "n/a" else f"{formatted} C"


def mm(value: Any) -> str:
    formatted = format_number(value, 1)
    return "n/a" if formatted == "n/a" else f"{formatted} mm"
