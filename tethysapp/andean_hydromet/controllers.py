from tethys_sdk.routing import controller

from .app import App
from .services.dashboard import load_dashboard_context, workspace_path


@controller(name="home", app_workspace=True)
def home(request, app_workspace):
    """Render the HydroMet Sentinel dashboard."""

    context = load_dashboard_context(workspace_path(app_workspace))
    return App.render(request, "home.html", context)
