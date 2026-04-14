(function () {
  function initStationMap() {
    var element = document.getElementById("station-map");
    if (!element || !window.L) {
      return;
    }

    var lat = parseFloat(element.dataset.lat);
    var lon = parseFloat(element.dataset.lon);
    var name = element.dataset.name || "Station";
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
      return;
    }

    element.innerHTML = "";
    var map = L.map(element, {
      zoomControl: true,
      scrollWheelZoom: false
    }).setView([lat, lon], 12);

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(map);

    L.marker([lat, lon]).addTo(map).bindPopup(name).openPopup();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initStationMap);
  } else {
    initStationMap();
  }
}());
