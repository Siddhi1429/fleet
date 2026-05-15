#FleetOps Pro - Enterprise Logistics Management

A production-quality Flutter application designed for high-scale fleet management, featuring real-time tracking, offline-first synchronization, and advanced app diagnostics.

## Key Features

- **Dashboard**: Infinite scrolling fleet list with search, status filtering, and skeleton loading.
- **Live Tracking**: Real-time vehicle movement on OpenStreetMap with simulated WebSocket updates, route history, and auto-camera following.
- **Offline Queue**: Robust synchronization manager that queues actions during connectivity loss and auto-syncs when back online.
- **App Diagnostics**: Built-in observability terminal and metrics dashboard to monitor API calls, socket states, and cache health.
- **Premium UI**: Modern glassmorphism design system with full Dark/Light mode support, smooth animations, and purple gradient branding.

## Tech Stack

- **Framework**: Flutter (Latest Stable)
- **State Management**: [Riverpod 2.x](https://riverpod.dev) (Notifiers & AsyncNotifiers)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) (Declarative routing with ShellRoutes)
- **Networking**: [Dio](https://pub.dev/packages/dio) with custom interceptors for mocking and diagnostics.
- **Local Storage**: [Hive](https://pub.dev/packages/hive) for fast, offline-first persistence.
- **Mapping**: [Flutter Map](https://pub.dev/packages/flutter_map) + [OpenStreetMap](https://www.openstreetmap.org/) for highly performant, customizable maps.
- **Connectivity**: [Connectivity Plus](https://pub.dev/packages/connectivity_plus) for real-time network state monitoring.

## Architecture (Clean Architecture)

The project follows a modular Clean Architecture approach:

```text
lib/
├── core/               # App-wide constants, theme, network, storage & common widgets
├── shared/             # Global entities/models used across multiple features
└── features/           # Independent feature modules
    └── feature_name/
        ├── data/       # Repositories & Data Sources
        ├── domain/     # Providers & Logic
        └── presentation/ # UI Screens & Widgets
```

## Design Tokens

- **Primary**: #6C3BFF (Purple)
- **Secondary**: #8B5CFF (Light Purple)
- **Accent**: #5B2EFF (Deep Purple)
- **Surface**: Dark/Light Glassmorphism cards

##  Getting Started

1. **Clone the repo**:
   ```bash
   git clone <repo_url>
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

---
*Created as a technical assignment for FleetOps Pro.*
