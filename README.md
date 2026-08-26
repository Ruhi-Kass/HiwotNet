# HiwotNet     


<img width="1024" height="572" alt="image" src="https://github.com/user-attachments/assets/b565924c-1f33-4d69-bf0b-a6ad1eddb426" />

<div align="center">

**A Next-Generation Real-Time Emergency Medical Dispatch System**

[![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Socket.io](https://img.shields.io/badge/RealTime-Socket.io-010101?style=for-the-badge&logo=socket.io&logoColor=white)](https://socket.io/)

HiwotNet is an end-to-end, real-time emergency dispatch ecosystem designed to drastically reduce ambulance response times. It provides a unified cross-platform interface for Patients, Dispatchers, Ambulance Crews, and Hospitals.

[Features](#-key-features) • [Architecture](#-system-architecture) • [Tech Stack](#-tech-stack) • [Getting Started](#-getting-started)

</div>

---

## ✨ Key Features

- **🚨 Patient SOS:** 1-tap emergency request with high-accuracy GPS coordinates.
- **🗺️ Live Telemetry:** Sub-millisecond real-time ambulance tracking via WebSockets. Watch the ambulance approach on a live map without refreshing.
- **⚡ Smart Dispatching:** Centralized dashboard for dispatchers to instantly assign the nearest available ambulance based on real-time location data.
- **📱 Unified Codebase:** A single Flutter application that adapts its UI and compiles to iOS/Android for mobile users, and Web for desktop dispatchers.
- **🏥 Hospital Handoff:** Notifies destination hospitals of incoming trauma patients with ETA and severity parameters.
- **🔒 Secure:** Role-Based Access Control (RBAC) and JWT authentication.

## 🏗️ System Architecture

HiwotNet is built on a highly scalable, decoupled architecture:

1. **`hiwotnet_backend` (Node.js/Express)**
   - The central nervous system. Handles authentication, database queries, and routing logic.
   - Uses **Prisma ORM** to interact with a **Supabase PostgreSQL** database.
   - Features a **Socket.io** WebSocket server for persistent, bi-directional real-time communication.

2. **`hiwotnet_frontend` (Flutter)**
   - A unified cross-platform frontend.
   - **Mobile (Android/iOS):** Patient App & Ambulance Crew App.
   - **Web:** Central Dispatcher Dashboard & Hospital Dashboard.
   - Built with the **Provider** pattern for state management and **GoRouter** for declarative role-based routing.

## 💻 Tech Stack

### Frontend (Cross-Platform)
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Routing:** GoRouter
- **Maps:** flutter_map (OpenStreetMap)
- **Real-Time:** socket_io_client

### Backend (REST & WebSockets)
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** PostgreSQL (Supabase)
- **ORM:** Prisma
- **Real-Time Engine:** Socket.io
- **Security:** JWT, bcrypt

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- [Node.js](https://nodejs.org/) (v18+)
- A [Supabase](https://supabase.com/) account (for Postgres DB)

### 1. Backend Setup (`hiwotnet_backend`)

```bash
# Navigate to the backend directory
cd hiwotnet_backend

# Install dependencies
npm install

# Set up environment variables
# Copy .env.example to .env and add your Supabase connection string and JWT Secret
cp .env.example .env

# Push Prisma Schema to database
npx prisma db push

# (Optional) Seed the database with hospitals and mock users
npx prisma db seed

# Start the development server
npm run dev
```

### 2. Frontend Setup (`hiwotnet_frontend`)

```bash
# Navigate to the frontend directory
cd hiwotnet_frontend

# Install Flutter dependencies
flutter pub get

# Run the app (select your target device, e.g., Chrome, Android Emulator, iOS Simulator)
flutter run
```

---

## 🛡️ Security & Privacy
HiwotNet handles sensitive medical and location data. All API routes are protected by JWT middleware. Socket connections authenticate via handshake tokens before allowing subscription to telemetry events.

---

<div align="center">
  <i>Built to save lives.</i>
</div>

