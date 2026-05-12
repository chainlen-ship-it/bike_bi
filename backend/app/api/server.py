# server.py
# FastAPI service that exposes the BigQuery extract as an HTTP endpoint so the
# dashboard's "Refresh from Google" button can trigger a fresh CSV export.
#
# Endpoints:
#   GET  /api/extract/status  - current state + last successful run timestamp
#   POST /api/extract         - kick off a new extract.py run (async)
#
# State is held in-process (single uvicorn worker assumed) and the last-success
# timestamp is persisted to backend/data/.last_extract.json so it survives
# container restarts.

from __future__ import annotations

import json
import os
import subprocess
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


ROOT_DIR = Path(__file__).resolve().parents[3]
DATA_DIR = ROOT_DIR / "backend" / "data"
STATE_FILE = DATA_DIR / ".last_extract.json"
EXTRACT_SCRIPT = ROOT_DIR / "backend" / "app" / "src" / "extract.py"

app = FastAPI(title="Cyclistic Extract API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

_state_lock = threading.Lock()
_state: dict = {
    "status": "idle",
    "started_at": None,
    "finished_at": None,
    "last_success_at": None,
    "error": None,
}

_credentials_lock = threading.Lock()
_google_credentials: dict = {
    "access_token": None,
    "expires_at": None,
    "project": None,
}


class GoogleAccessTokenRequest(BaseModel):
    access_token: str = Field(..., min_length=20)
    project: str = Field(..., min_length=3)
    expires_in_minutes: int = Field(default=55, ge=1, le=120)


def _load_persisted_state() -> None:
    if not STATE_FILE.exists():
        return
    try:
        data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
        last = data.get("last_success_at")
        if last:
            _state["last_success_at"] = last
    except Exception:
        pass


def _save_persisted_state() -> None:
    try:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text(
            json.dumps({"last_success_at": _state["last_success_at"]}, indent=2),
            encoding="utf-8",
        )
    except Exception:
        pass


_load_persisted_state()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _parse_iso(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _credential_status() -> dict:
    with _credentials_lock:
        token = _google_credentials.get("access_token")
        expires_at = _google_credentials.get("expires_at")
        project = _google_credentials.get("project")

    expires = _parse_iso(expires_at)
    active = bool(token and project and expires and expires > datetime.now(timezone.utc))
    return {
        "status": "ready" if active else "missing",
        "has_token": active,
        "project": project if active else None,
        "expires_at": expires_at if active else None,
    }


def _extract_env() -> dict[str, str]:
    env = dict(os.environ)
    credential_state = _credential_status()
    if credential_state["has_token"]:
        with _credentials_lock:
            env["GOOGLE_OAUTH_ACCESS_TOKEN"] = str(_google_credentials["access_token"])
            env["YOUR_PROJECT"] = str(_google_credentials["project"])
            env["GCP_PROJECT"] = str(_google_credentials["project"])
    return env


def _run_extract() -> None:
    with _state_lock:
        _state["status"] = "running"
        _state["started_at"] = _now_iso()
        _state["finished_at"] = None
        _state["error"] = None

    try:
        proc = subprocess.run(
            [sys.executable, str(EXTRACT_SCRIPT)],
            capture_output=True,
            text=True,
            cwd=str(ROOT_DIR),
            env=_extract_env(),
            timeout=60 * 30,
        )
        finished = _now_iso()
        if proc.returncode == 0:
            with _state_lock:
                _state["status"] = "success"
                _state["finished_at"] = finished
                _state["last_success_at"] = finished
            _save_persisted_state()
        else:
            tail = (proc.stderr or proc.stdout or "extract failed").strip()
            with _state_lock:
                _state["status"] = "error"
                _state["finished_at"] = finished
                _state["error"] = tail[-2000:]
    except subprocess.TimeoutExpired:
        with _state_lock:
            _state["status"] = "error"
            _state["finished_at"] = _now_iso()
            _state["error"] = "extract.py timed out after 30 minutes"
    except Exception as exc:
        with _state_lock:
            _state["status"] = "error"
            _state["finished_at"] = _now_iso()
            _state["error"] = f"{type(exc).__name__}: {exc}"


def _fallback_last_success() -> str | None:
    stations = DATA_DIR / "stations.csv"
    if not stations.exists():
        return None
    return datetime.fromtimestamp(stations.stat().st_mtime, timezone.utc).isoformat()


@app.get("/api/extract/status")
def get_status() -> dict:
    with _state_lock:
        snapshot = dict(_state)
    if not snapshot["last_success_at"]:
        snapshot["last_success_at"] = _fallback_last_success()
    return snapshot


@app.post("/api/extract", status_code=202)
def post_extract() -> dict:
    with _state_lock:
        if _state["status"] == "running":
            raise HTTPException(status_code=409, detail="Extract already in progress")

    if not _credential_status()["has_token"] and not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        raise HTTPException(
            status_code=401,
            detail="Google credentials are required. Use Gather Google Credentials first.",
        )

    thread = threading.Thread(target=_run_extract, daemon=True)
    thread.start()
    return {"status": "started"}


@app.get("/api/google-credentials/status")
def get_google_credentials_status() -> dict:
    return _credential_status()


@app.post("/api/google-credentials", status_code=204)
def post_google_credentials(payload: GoogleAccessTokenRequest) -> None:
    expires_at = datetime.now(timezone.utc).timestamp() + (payload.expires_in_minutes * 60)
    expires_iso = datetime.fromtimestamp(expires_at, timezone.utc).isoformat()
    with _credentials_lock:
        _google_credentials["access_token"] = payload.access_token.strip()
        _google_credentials["project"] = payload.project.strip()
        _google_credentials["expires_at"] = expires_iso


@app.delete("/api/google-credentials", status_code=204)
def delete_google_credentials() -> None:
    with _credentials_lock:
        _google_credentials["access_token"] = None
        _google_credentials["expires_at"] = None
        _google_credentials["project"] = None


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok"}
