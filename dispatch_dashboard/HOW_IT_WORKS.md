# HIWONET-RESPONSE — System Architecture & How It Works

## 1. Executive Summary & Vision

**HIWONET-RESPONSE** is a unified emergency medical response and intelligent ambulance dispatch console built specifically for the metropolitan region of **Addis Ababa, Ethiopia**. 

The platform bridges emergency medical callers, fleet ambulances, dispatch operators, and receiving specialized hospital trauma centers into a synchronized, low-latency digital workflow.

The application is structured into two isolated consoles hosted in a single responsive Flutter Web codebase:
1. **Dispatcher Workstation (`/dashboard`)**: The operational hub where active operators monitor GIS telemetry, prioritize emergency triage queues, track nearest units, and manage ambulance routing.
2. **System Administrator Console (`/admin/*`)**: The command and governance panel where system administrators provision personnel, approve dispatcher applications, manage hospital trauma capacities, inspect fleet health, and review immutable audit ledgers.

---

## 2. Codebase Directory & Component Architecture

Below is the file structure and the role of each module in the codebase:

```
dispatch_dashboard/
├── lib/
│   ├── main.dart                       # App entry point, GoRouter table, auth redirects & theme binding
│   ├── firebase_options.dart           # Platform-specific Firebase credentials and web configs
│   ├── data/
│   │   └── network_stats.dart          # Canonical city-wide totals (48 ambulances, 28 hospitals)
│   ├── models/
│   │   ├── fleet_models.dart           # Domain entities: FleetUnit, IncomingRequest, RouteSuggestion
│   │   └── admin_models.dart           # Domain entities: UserAccount, RegistrationRequest, HospitalRecord, AuditLog
│   ├── services/
│   │   ├── auth_service.dart           # RBAC engine, session persistence, TOTP MFA validation, profile state
│   │   ├── admin_repository.dart       # User provisioning, conflict checking, approval pipeline & audit logging
│   │   ├── fleet_repository.dart       # Live ambulance GPS telemetry, incident streams, hospital bed monitoring
│   │   ├── firebase_service.dart       # Firestore seeding and cloud synchronization
│   │   ├── image_picker_service.dart   # Cross-platform abstract contract for file selection
│   │   ├── image_picker_web.dart       # Browser FileUploadInputElement & FileReader (Base64 data URL)
│   │   ├── image_picker_stub.dart      # Fallback stub for non-web environments
│   │   ├── session_storage.dart        # Abstract contract for web session storage
│   │   ├── session_storage_web.dart    # window.localStorage persistence for active session & photo
│   │   └── session_storage_stub.dart   # In-memory session fallback stub
│   ├── theme/
│   │   └── app_theme.dart              # Dual-mode light/dark ThemeData, AppColors, and ThemeToggleButton
│   ├── widgets/
│   │   ├── brand_bar.dart              # Red glass navigation bar with clamped max-width containers
│   │   ├── icon_rail.dart              # Left vertical navigation rail with quick-return admin button
│   │   ├── admin_scaffold.dart         # Red command header & sidebar layout for all /admin pages
│   │   ├── dispatcher_account_dialog.dart # View-only credential card + photo upload dialog
│   │   ├── dispatcher_avatar.dart      # Circular operator avatar with status indicator dot
│   │   ├── live_map_canvas.dart        # CustomPainter Addis Ababa GIS map canvas with route vector overlay
│   │   ├── status_badge.dart           # Unit status pill (Available, En Route, On Scene, Offline)
│   │   ├── status_pill.dart            # Generic rounded status pill
│   │   └── account_status_pill.dart    # User account status pill (Active vs. Suspended)
│   └── screens/
│       ├── landing_page.dart           # Public marketing & role portal showcase with theme sync
│       ├── registration_page.dart      # Dispatcher registration form with conflict prevention
│       ├── login_page.dart             # Dispatcher login card with pre-seeded credentials
│       ├── dashboard_page.dart         # Dispatcher workstation (Map, Triage, Analytics, Fleet)
│       └── admin/
│           ├── admin_login_page.dart   # Admin 2FA login card (email + password + 6-digit TOTP)
│           ├── admin_dashboard_page.dart # System overview, fleet metrics & quick action cards
│           ├── user_management_page.dart # Dispatcher approval queue & staff RBAC directory
│           ├── hospital_registry_page.dart # 28 Addis Ababa specialized hospital trauma beds & ambulances
│           ├── audit_logs_page.dart    # Searchable, filterable immutable system audit trail
│           └── admin_analytics_page.dart # City-wide response time & sub-city coverage analytics
├── test/
│   ├── dispatcher_workflow_test.dart   # Unit & integration tests for auth, approval, and profile sync
│   └── phase6_hardening_test.dart      # Regression and edge-case validation
├── README.md                           # Quick start, credentials & run guide
└── HOW_IT_WORKS.md                     # Comprehensive architecture and test documentation (this file)
```

---

## 3. Technology Stack & Architectural Pillars

| Component | Technology | Role & Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | **Flutter Web (Dart 3.x)** | High-performance responsive UI rendering across desktop, tablet, and mobile browsers. |
| **Routing & Navigation** | **`go_router` (Declarative Routing)** | Separate route hierarchies for Dispatcher and Admin with deep linking and guard redirects. |
| **Backend & Sync** | **Firebase Firestore & Realtime DB** | Cloud database sync for incidents, ambulances, audit logs, and registrations. |
| **Local Resilience** | **`SessionStorage` & In-Memory Controllers** | Seamless offline fallback for testing, evaluation, and instant UI state preservation. |
| **Theme System** | **`AppThemeController` & `AppColors`** | Centralized, reactive Light/Dark mode tokens maintaining 7:1+ contrast compliance. |
| **Asset & Image Engine** | **`ImagePickerService` (Base64 Web File API)** | Zero-dependency browser file picker for personnel badge photos and profile pictures. |

---

## 4. Authentication, Security & RBAC Governance

### 4.1 Role Isolation & Route Gating
To enforce strict Ethiopian Ministry of Health (MOH) data governance, administrative and operational dispatch credentials belong to separate authentication pools:
- **Dispatcher accounts** can only access operational workstation routes (`/dashboard`) and cannot reach `/admin/*`.
- **System Administrator accounts** have elevated authority across the platform, including access to user RBAC provisioning, hospital registries, and audit logs.
- When an administrator visits the dispatcher console (e.g. to inspect live routing or view dispatcher workstation performance), a prominent **"Back to Admin Console"** navigation button is rendered on the header and navigation rail to easily return to `/admin`.

### 4.2 Pre-Seeded Evaluation Credentials
The system comes pre-seeded with verified test accounts that work out of the box (with or without a live Firebase connection):

- **Authorized Dispatcher**:
  - Identifier / Email: `dispatcher01` or `dispatcher01@hiwonet.et`
  - Password: `hiwonet-2026`
  - Callsign: `ECHO-101`
  - Dispatch Station: Addis Ababa Central Command
- **System Administrator**:
  - Email: `admin@hiwonet.et`
  - Password: `command-2026`
  - 2FA One-Time Passcode (OTP): `482913`
  - Callsign: `COMMAND-ALPHA`

---

## 5. Dispatcher Registration & Admin Approval Workflow

### 5.1 Upfront Conflict Detection
To maintain system integrity, duplicate registrations are automatically rejected upfront:
- The system verifies that no two accounts share the same **Employee ID**, **Email**, or **Radio Callsign**.
- If a dispatcher who is already registered or whose application is currently pending attempts to re-register, the submission is blocked with an explicit error message.

### 5.2 Auto-Generated Personnel Identifiers
To prevent operator collisions and human error during intake:
- **Employee ID**: Automatically assigned by the central system (format: `DSP-2026-XXXX`).
- **Radio Callsign**: Generated systematically using NATO phonetic callsigns and unit digits (e.g., `ALPHA-09`, `BRAVO-14`, `DELTA-32`).

### 5.3 Addis Ababa Sub-City Selection
Dispatch stations are categorized strictly by Addis Ababa administrative sub-cities:
- **Central Sub-Cities**:
  - *Addis Ketema* (Northwestern center, home to Addis Mercato)
  - *Arada* (Historic core, Piassa & 4 Kilo)
  - *Kirkos* (Central business and diplomatic district)
  - *Lideta* (West-central hub)
- **Outer Sub-Cities**:
  - *Akaki Kality* (Southern primary industrial zone)
  - *Bole* (Southeastern commercial hub & Bole International Airport)
  - *Gulele* (Northern sector bordering Entoto)
  - *Kolfe Keranio* (Western corridor)
  - *Lemi Kura* (Eastern sub-city)
  - *Nifas Silk-Lafto* (Southwestern sector)
  - *Yeka* (Northeastern sector)

### 5.4 Review & Instant Provisioning
1. An applicant fills out the registration form at `/register`.
2. The registration request is saved into the pending review queue (`registrationRequests`).
3. An administrator navigates to `/admin/users` (User Management), reviews the credentials, and clicks **Approve**.
4. Upon approval:
   - The pending application is immediately removed from the pending list.
   - A new active user profile is created in the staff directory.
   - The operator can immediately log in at `/login` with their credentials.

---

## 6. Dispatcher Workstation (`/dashboard`)

The Dispatcher Workstation is designed as a mission-critical operations dashboard:

### 6.1 Red Command Header & White Typography
- Designed with an authoritative deep crimson red command gradient (`#991B1B` &rarr; `#DC2626`) with `#7F1D1D` borders.
- All titles, status metrics, search inputs, dropdown labels, and buttons feature high-contrast **crisp white typography** (`#FFFFFF` and `#FFFFFF` with 85% opacity).
- **Responsive Zero-Overflow**: Utilizes responsive `LayoutBuilder` logic with horizontal scroll containers. On viewports below `1120px` (tablets and compact screens), the bar splits into two clean rows so that navigation buttons, search fields, and profile badges never collide or produce yellow/black hazard bars.

### 6.2 Context-Sensitive Page Toolbars
The top bar dynamically adjusts its toolbars depending on the active tab:
- **Live Map (Tab 0)**: Displays map status indicators (*Available*, *Active*, *Avg. ETA*) alongside live location search.
- **Emergency Requests (Tab 1)**: Displays pending emergency counter, caller/incident search, Addis Ababa neighborhood selector, and Priority filters (All, P1, P2).
- **Live Analytics (Tab 2)**: Displays target benchmarks (*Target ETA <8m*, *99.8% Online Telemetry*, *11/11 Sub-cities Monitored*) and live telemetry status, hiding unrelated caller filters.
- **Fleet Management (Tab 3)**: Displays fleet vehicle indicators (*Total Ambulances*, *Ready Units*, *En Route Units*) and ambulance unit search.

### 6.3 Dispatcher Personnel Profile Dialog
Clicking the dispatcher avatar on the top bar or left navigation rail opens the **Dispatcher Personnel Profile**:
- **Strictly View-Only Credentials**: The operator's Full Name, Radio Callsign, Command Center / Sub-city, Employee ID, Work Email, and Operational Role are strictly read-only and locked by Administration.
- **Photo Upload Capability**: Operators can upload an official badge photo directly from their computer (via `ImagePickerService`) or choose quick avatar icons. Once uploaded, the photo instantly synchronizes across memory and session storage without requiring page refreshes.
- **End Shift & Log Out**: Operators can end their shift through a confirmed logout action that returns them to `/login`.

### 6.4 28 Addis Ababa Specialized Hospitals Registry
The system integrates all major tertiary, trauma, and specialized hospitals across Addis Ababa:
- *ALERT Comprehensive Specialized Hospital* (Kolfe Keranyo — Trauma & Orthopedics)
- *Tikur Anbessa Specialized Hospital / Black Lion* (Lideta — Central Teaching Center)
- *St. Paul's Hospital Millennium Medical College* (Gulele — Referral Center)
- *AaBET Hospital* (Dej Zewdu Aba Koran St — Dedicated Burn, Emergency & Trauma)
- *Myungsung Christian Medical Centre / Korean Hospital* (Gerji, CMC area)
- *Dream Orthopedics, Trauma and Spine Specialty Center* (Bole)
- *Nordic Medical Centre* (Bole Sub City)
- *Bethesda American Medical Plaza* (Opposite Capital Hotel)
- *Yekatit 12 Hospital Medical College* (Arada)
- *Zewditu Memorial Hospital* (Kirkos)
- *Menelik II Referral Hospital* (Arada)
- *Ras Desta Damtew Memorial Hospital* (Addis Ketema)
- *Armed Forces Comprehensive Specialized Hospital* (Lideta)
- *Federal Police Hospital* (Addis Ababa)
- *St. Peter’s Specialized Hospital* (Shiromeda, Addis Ketema)
- *Amanuel Mental Specialized Hospital* (Addis Ketema)
- *Gandhi Memorial Hospital* (Kazanchis / Kirkos)
- *St. Gabriel General Hospital* (Bole)
- *Ethio Tebib Hospital* (Mexico Area)
- *Kadisco General Hospital* (Saris / Gerji)
- *Hallelujah General Hospital* (Piassa)
- *Landmark General Hospital* (Kirkos / Bole Road)
- *Addis Hiwot Hospital* (Haya Hulet, Bole)
- *Teklehaimanot General Hospital* (Addis Ababa)
- *Balcha Hospital* (Kirkos / Lideta)
- *Nucleus General Hospital* (German Square, Mekanissa)
- *Girum Hospital* (Addis Ketema)
- *Yanet General Hospital* (Ayat, Derartu Tulu Square)

---

## 7. How to Run the Application

### 7.1 Prerequisites
- **Flutter SDK**: Version 3.19 or higher.
- **Web Browser**: Chrome, Edge, Firefox, or Safari.

### 7.2 Running Locally
Navigate to the project root directory and start the web server:

```powershell
cd "dispatch_dashboard"
flutter pub get
flutter run -d web-server --web-port=5055 --web-hostname=127.0.0.1
```

Once compiled, open your browser and navigate to:
👉 **`http://127.0.0.1:5055`**

---

## 8. How to Test Everything

### 8.1 Automated Unit & Integration Tests
The repository includes a comprehensive unit test suite located at [`test/dispatcher_workflow_test.dart`](test/dispatcher_workflow_test.dart).

To execute the test suite:
```powershell
cd "dispatch_dashboard"
flutter test test/dispatcher_workflow_test.dart
```

#### What the automated tests verify:
1. **Default Dispatcher Authentication**: Confirms that signing in with `dispatcher01` / `hiwonet-2026` populates valid operator credentials, employee IDs, callsigns, and dispatch centers.
2. **Profile Synchronization**: Verifies that updating profile attributes triggers change notifications (`profileUpdateNotifier`) and syncs across active listeners.
3. **Admin Approval Pipeline**: Submits a new registration, verifies it enters the pending queue, simulates admin approval, verifies its removal from pending, verifies the new user appears in active staff, and confirms the user can immediately log in with their password.
4. **Duplicate Prevention**: Verifies that duplicate submissions with existing emails, employee IDs, or callsigns are rejected with descriptive conflict errors.
5. **View-Only Credential Immutability**: Confirms that photo updates succeed while operational credentials (name, callsign, center, employee ID) remain securely locked.
6. **Role Isolation**: Verifies that the `isAdmin` flag strictly differentiates system administrators from dispatchers.

### 8.2 Manual Test Scenarios

#### Scenario A: Dispatcher Workflow
1. Navigate to `http://127.0.0.1:5055/login`.
2. Enter operator ID `dispatcher01` and password `hiwonet-2026`.
3. Click **Sign In** &rarr; You arrive at the **Dispatcher Workstation** (`/dashboard`).
4. Click through the tabs on the left navigation rail:
   - **Live Map**: Check nearest-unit routing and live ambulance positions.
   - **Emergency Requests**: Test the Addis Ababa sub-city filter and P1/P2 priority dropdowns.
   - **Live Analytics**: Confirm KPIs and telemetry indicators render without layout overflows.
   - **Fleet Management**: Review unit status and telemetry.
5. Click on the operator avatar on the top bar:
   - Verify all credentials (callsign, sub-city, ID) are displayed as locked/verified.
   - Click **Upload Photo** to test file selection.
   - Notice that the photo updates immediately on the avatar and top bar.
6. Click **Log Out** to confirm shift termination and return to `/login`.

#### Scenario B: Admin Workflow & Registration Approval
1. Open `http://127.0.0.1:5055/register` and submit a new dispatcher registration (the system will auto-assign an Employee ID and Callsign).
2. Navigate to `http://127.0.0.1:5055/admin/login`.
3. Sign in with:
   - Email: `admin@hiwonet.et`
   - Password: `command-2026`
   - 2FA Code: `482913`
4. On the **Admin Dashboard**, click on **User Management** (`/admin/users`).
5. Find the pending application under *Pending Registrations* and click **Approve**.
6. Verify that the request disappears from pending and appears under the *Active Personnel* table.
7. Click **Switch to Dispatcher Live Map** from the admin overview or click the workstation icon next to a dispatcher.
8. Verify that on the dispatcher dashboard header, a prominent **"Back to Admin Console"** button is displayed.
9. Click **"Back to Admin Console"** &rarr; You are returned immediately to `/admin`.

#### Scenario C: Responsive & Tablet Testing
1. Resize your browser window between 600px and 1200px width.
2. Verify that the red header transitions smoothly into two rows without any horizontal overflow.
3. Open the **Analytics** tab and verify the 3 KPI cards stack responsively without producing yellow/black hazard bars.
4. Open the **Fleet Management** tab and verify the roster header row wraps gracefully.
5. On the public landing page, toggle the Theme button between **Light** and **Dark** mode and verify all cards, text, and containers update their contrast instantly.
