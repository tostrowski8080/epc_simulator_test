
import requests

class EpcSimulatorLibrary:
    """Counter starts at 0; ROBOT_LIBRARY_SCOPE=TEST gives a new instance per test case."""

    ROBOT_LIBRARY_SCOPE = "TEST"

    def __init__(self, base_url: str = "http://localhost:8000") -> None:
        self._base = base_url.rstrip("/")

    def _get(self, path: str, params: dict = None) -> dict:
            response = requests.get(f"{self._base}{path}", params=params)
            response.raise_for_status()
            return response.json()

    def _post(self, path: str, body: dict = None) -> dict:
            response = requests.post(f"{self._base}{path}", json=body or {})
            response.raise_for_status()
            return response.json()

    def _delete(self, path: str) -> dict:
            response = requests.delete(f"{self._base}{path}")
            response.raise_for_status()
            return response.json()

    def attach_ue(self, ue_id: int) -> dict:
            return self._post("/ues", {"ue_id": int(ue_id)})

    def detach_ue(self, ue_id: int) -> dict:
            return self._delete(f"/ues/{ue_id}")

    def list_ues(self) -> list:
            return self._get("/ues")["ues"]

    def get_ue(self, ue_id: int) -> dict:
            return self._get(f"/ues/{ue_id}")

    def reset_simulator(self) -> dict:
            return self._post("/reset")

    def add_bearer(self, ue_id: int, bearer_id: int) -> dict:
            return self._post(f"/ues/{ue_id}/bearers", {"bearer_id": int(bearer_id)})

    def delete_bearer(self, ue_id: int, bearer_id: int) -> dict:
            return self._delete(f"/ues/{ue_id}/bearers/{bearer_id}")

    def start_traffic(self, ue_id, bearer_id, protocol="udp", mbps=None, kbps=None, bps=None):
        body = {"protocol": protocol}
        if mbps is not None:
            body["Mbps"] = float(mbps)
        if kbps is not None:
            body["kbps"] = float(kbps)
        if bps is not None:
            body["bps"] = float(bps)
        return self._post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", body)
    
    def stop_traffic(self, ue_id: int, bearer_id: int = None) -> dict:
        return self._delete(f"/ues/{ue_id}/bearers/{bearer_id}/traffic")

    def get_traffic_stats(self, ue_id, bearer_id):
        return self._get(f"/ues/{ue_id}/bearers/{bearer_id}/traffic")