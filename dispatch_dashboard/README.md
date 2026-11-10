# HIWONET-RESPONSE — Dispatcher & Admin Web Console (Flutter)

A unified emergency medical response and dispatch management system engineered in **Flutter Web** for Addis Ababa, Ethiopia.

The application connects callers, fleet ambulances, dispatch operators, and specialized hospital trauma centers through two dedicated consoles operating on independent route hierarchies:

- **Dispatcher Workstation** (`/dashboard`): 
  - Landing Page (`/`) &rarr; Dispatcher Registration (`/register`) &rarr; Dispatcher Login (`/login`) &rarr; Live Map, Emergency Triage, Telemetry Analytics & Fleet Management (`/dashboard`).
- **Admin Command Console** (`/admin/*`):
  - Admin Login with mandatory 2FA OTP (`/admin/login`) &rarr; Command Dashboard (`/admin`) &rarr; User Management & RBAC Provisioning (`/admin/users`) &rarr; Hospital & Ambulance Registry (`/admin/registry`) &rarr; System & Audit Logs (`/admin/logs`) &rarr; City-Wide Response Analytics (`/admin/analytics`).

---

## Quick Start — How to Run Locally

### Prerequisites
- **Flutter SDK**: Version 3.19+ (with Web support enabled)
- **Web Browser**: Google Chrome, Microsoft Edge, Firefox, or Safari

### Run the Web Server

From the `dispatch_dashboard` directory:

```bash
cd dispatch_dashboard
flutter pub get
flutter run -d web-server --web-port=5055 --web-hostname=127.0.0.1
```

Once compiled, launch your browser and navigate to:
👉 **`http://127.0.0.1:5055`**

---

## Pre-Seeded Credentials for Testing

Both consoles feature built-in test accounts that work out of the box with zero external setup required:

### 1. Emergency Dispatcher Account
- **Portal URL**: `http://127.0.0.1:5055/login`
- **Operator ID**: `dispatcher01` (or `dispatcher01@hiwonet.et`)
- **Password**: `hiwonet-2026`
- **Callsign**: `ECHO-101`
- **Dispatch Center**: Addis Ababa Central Command

### 2. System Administrator Account
- **Portal URL**: `http://127.0.0.1:5055/admin/login`
- **Email**: `admin@hiwonet.et`
- **Password**: `command-2026`
- **2FA OTP Code**: `482913`
- **Callsign**: `COMMAND-ALPHA`

---

## Key Features & User Workflows

### 1. Dispatcher Workstation (`/dashboard`)
- **Command Red Header**: Deep crimson emergency gradient (`#991B1B` &rarr; `#DC2626`) with high-contrast white text, icons, and contextual controls.
- **Responsive Zero-Overflow**: Automatically adapts to desktop, tablet, and mobile viewport widths with fluid flex layouts, preventing RenderFlex overflows.
- **Context-Sensitive Navigation**:
  - **Live Map**: Real-time GPS ambulance markers, interactive route selection, nearest-unit calculation, and one-click dispatch execution.
  - **Emergency Requests**: Live incoming triage queue, Addis Ababa neighborhood filtering, and P1/P2 urgency filtering.
  - **Live Analytics**: Response time KPIs, fleet readiness metrics, and call-to-dispatch benchmarks.
  - **Fleet Management**: Complete unit status roster (Available, En Route, On Scene, Offline) and GPS telemetry feeds.
- **Dispatcher Personnel Profile**:
  - Secure view-only credentials (Full Name, Radio Callsign, Command Center / Sub-city, Employee ID, Email).
  - Photo upload directly from local storage with real-time sync across memory and session cache.
  - Shift termination & logout action.

### 2. Administrator Command Console (`/admin/*`)
- **Dual-Factor Authentication**: Mandatory 6-digit TOTP validation (`482913`) protecting administrative endpoints.
- **User Management & Approval Queue**:
  - Review submitted dispatcher registration requests.
  - One-click approval that removes the request from pending, promotes the dispatcher into active staff, and instantly enables their login.
  - Role management (Caller, Crew, Hospital Staff, Dispatcher, Admin) and account suspension/reinstatement.
- **Hospital Registry (28 Facilities)**:
  - Real-time trauma center capacity tracking across major Addis Ababa hospitals (ALERT, Tikur Anbessa / Black Lion, St. Paul's, AaBET, MCM Korean, Dream Orthopedics, Nordic, etc.).
- **Audit Logs**:
  - Timestamped, immutable audit trail logging all role modifications, registrations, suspensions, logins, and dispatches.
- **"Back to Admin Console" Link**:
  - Seamless toggle button allowing administrators inspecting the dispatcher live map to instantly return to `/admin`.

### 3. Public Landing Page (`/`)
- High-contrast, theme-synchronized landing showcase featuring city-wide fleet metrics (48 Ambulances, 28 Partner Hospitals, 6.8m Avg ETA).
- Complete Dark & Light theme synchronization across all hero sections, stat cards, feature cards, and role portals.
- Smooth anchored scrolling to Features, Architecture, Security, and Contact sections.

---

## Architecture & How It Works

For an in-depth architectural breakdown, data flow diagrams, security mechanisms, and complete testing guides, see:
📘 **[`HOW_IT_WORKS.md`](HOW_IT_WORKS.md)**

---

## Automated Test Suite

Run the automated test suite covering authentication, RBAC, registration workflows, and profile synchronization:

```bash
flutter test test/dispatcher_workflow_test.dart
```
