# 🚀 HIWONET-RESPONSE — How to Run & Quickstart Guide

Autonomous Emergency Medical Dispatch & Spatial Fleet Tracking Platform  
**Addis Ababa, Ethiopia • Senior CS Capstone Project 2026**

---

## ⚡ Option 1: The 1-Click Method (Easiest)

You can run the entire platform by simply double-clicking the provided batch scripts in this folder:

| Script to Double-Click | What It Does |
| :--- | :--- |
| **`RUN_APP.bat`** | **Launches the Flutter Web App**. Automatically cleans stale locks, detects Flutter, and gives you a 1-click prompt to open directly in Google Chrome or as a web server on `http://localhost:5050`. |
| **`RUN_TESTS.bat`** | **Executes the 479 Automated Tests** (Unit, Concurrency Mutex, Stress, System Integration, Alpha Exploits) with a 100% pass rate in ~5 seconds. |
| **`WATCH_DEMO.bat`** | **Opens the HD Video Demo Showcase** in your web browser with interactive chapter bookmarks and technical cards. |

---

## 💻 Option 2: Run via Terminal / Command Prompt

If you prefer using PowerShell, Command Prompt, or VS Code terminal:

### 1. Start the Flutter Web Application

Open a terminal in this project folder and run:

```powershell
cd dispatch_dashboard
flutter run -d chrome
```

*Or to run as a background web server on port 5050:*

```powershell
cd dispatch_dashboard
flutter run -d web-server --web-port=5050 --web-hostname=localhost
```

Once running, open your web browser to:  
👉 **[http://localhost:5050/](http://localhost:5050/)**

---

### 2. Run the Automated Test Suite (479 Tests)

Open a terminal and run:

```powershell
cd hiwonet_firebase
npm test
```

This runs the comprehensive multi-tier test suite:
* **Tier 1**: 407 Security Rules Unit Tests
* **Tier 2**: 50 Cloud Functions Integration Tests
* **Tier 3**: Stress & High-Concurrency Mutex Race Tests (50 & 100 simultaneous dispatches)
* **Tier 4**: 10 End-to-End System Tests
* **Tier 5**: 10 Alpha & Penetration Scenarios
* **Total**: **479 / 479 Passed (100.0%)**

---

## 🗺️ Portal Navigation & Live URLs

When the web server is running on `http://localhost:5050/`, you can explore every screen:

| Screen / Portal | URL Path | Purpose |
| :--- | :--- | :--- |
| **Public Landing Portal** | `/` | Marketing landing page with red frosted-glass header, architecture breakdown, emergency hotline, and 3-column MOH-EMS footer. |
| **Dispatcher Station Login** | `/#/login` | Authentication gate for emergency dispatchers and operators. |
| **Dispatcher Access Request** | `/#/register` | Structured onboarding portal with radio callsign and station clearance. |
| **Live Dispatcher Map** | `/#/dashboard` | Central dispatch console: live Addis Ababa map, 24 GPS ambulances, triage queue, ACID atomic mutex lock, and Haversine routing. |
| **Administrator Login** | `/#/admin/login` | Security gate for central command supervisors and admins. |
| **Admin Overview Dashboard** | `/#/admin` | Executive telemetry, average response time (7.2 min), and fleet metrics. |
| **User & RBAC Management** | `/#/admin/users` | Manage dispatcher permissions, callsign assignment, and account approvals. |
| **Hospital & Bed Registry** | `/#/admin/registry` | Real-time ICU and emergency bed synchronization for Black Lion, St. Paul's, and Yekatit 12 hospitals. |
| **Cryptographic Audit Trail** | `/#/admin/logs` | Immutable audit log of every triage, unit assignment, and status transition. |

---

## 🔑 Demo Credentials (Quick Reference)

For testing and demonstration, use these accounts:

### Dispatcher Console:
* **Portal Link**: Click **"Portal Sign In"** on the header or go to `/#/login`
* **Station**: Central Command Station (Bole / Churchill Ave)
* **Sample Radio Callsign**: `ALPHA-01`

### Admin Command Center:
* **Portal Link**: Click **"Admin"** on the header or go to `/#/admin/login`
* **Email**: `admin@hiwonet.et`
* **Password**: `admin123` (or click *Bypass / Quick Access* for instant demo access)

---

## 🎬 Demo Video & Presentation Artifacts

If you need to show the demo to your professor, advisors, or examiners without running code:

1. Double-click **`HIWONET_DEMO_SHOWCASE.html`** or **`WATCH_DEMO.bat`** to open the interactive video presentation in Chrome or Edge.
2. The raw high-definition video is available at **`HIWONET_DEMO_VIDEO.webm`** (15.8 MB) and can be embedded directly into PowerPoint or Google Slides.

---

## 🛠️ Common Troubleshooting

### 1. "Flutter failed to open a file at lockfile"
If a previous Flutter process left a lock in `C:\flutter\bin\cache\lockfile`, simply run `RUN_APP.bat` — it automatically deletes stale lockfiles before starting.  
Alternatively, run this PowerShell command:
```powershell
Remove-Item "C:\flutter\bin\cache\lockfile" -Force -ErrorAction SilentlyContinue
```

### 2. "Port 5050 is already in use"
If port 5050 is occupied by a background process, run on another port or terminate the old process:
```powershell
flutter run -d web-server --web-port=5055 --web-hostname=localhost
```
Then visit `http://localhost:5055/`.

### 3. Hot Reload & Interactive Commands
While the Flutter command is running in your terminal:
* Press **`r`** for **Hot Reload** (instant visual updates).
* Press **`R`** for **Hot Restart** (full state reset in < 500ms).
* Press **`q`** to safely stop the server.
