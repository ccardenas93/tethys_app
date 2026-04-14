from tethys_sdk.base import TethysAppBase


class App(TethysAppBase):
    """Tethys app class for Andean HydroMet Sentinel."""

    name = "Andean HydroMet Sentinel"
    index = "home"
    icon = "andean_hydromet/images/icon.svg"
    package = "andean_hydromet"
    root_url = "andean-hydromet"
    color = "#177e89"
    description = (
        "Station-calibrated hydro-meteorological forecasts for Quito's Inaquito "
        "station using INAMHI observations and ECMWF open data."
    )
    tags = "Hydrology, Meteorology, Forecasting, Ecuador, ECMWF, INAMHI"
    enable_feedback = False
