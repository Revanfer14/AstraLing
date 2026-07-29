# AstraLing

> **A discovery, coordination, and payment layer for Indonesia's street vendors.**
> AstraLing pairs a live vendor radar with ping-based coordination and QRIS payment to bring roaming PKL (Pedagang Kaki Lima) into the AstraPay ecosystem.

---

## Overview

AstraLing is a native iOS MVP built for the **AstraPay Hackathon 2026**. It connects customers with **active mobile street vendors (PKL)** in real time — a **discovery + trust + payment layer on top of AstraPay**, not a food-delivery app and not a maps app.

One build, **two roles**, one Firebase project. The surface a device shows is decided entirely by the signed-in account's role (`users/{uid}.role`), so Customer and Merchant never share a UI, only a database.

Core loop — **Ping-to-Pay**:

```
Discover → Ping → (Chat to coordinate) → Meet Offline → Pay via QRIS → Earn Points → Insight
```

Deck framework — **TEMU**: **TE**mukan pedagang aktif · **M**ulai ping hingga pembayaran · **U**ngkap insight & bangun kepercayaan.

Positioning guardrail: the customer still buys **offline**, and the vendor still sells **while roaming**. AstraLing only digitizes the *finding*, the *coordinating* (ping + chat), and the *paying*. There is no cart, no checkout, no delivery, and no second payment provider.

---

## Features

- **Dual-role single app** — Customer and Merchant surfaces in one build, routed by Firestore role, never importing each other's code
- **Live Vendor Map** — real-time `collectionGroup("presence")` listener, filtered to vendors currently selling
- **Ping-to-Pay core loop** — Discover → Ping → Chat → Meet Offline → Pay → Points → Insight
- **Keliling Mode** — a one-tap presence toggle for the vendor; live location only pushes while it's on
- **Deterministic 1:1 chat** — opened automatically by a ping, no separate "start chat" step
- **Mocked QRIS payment** — swappable `PaymentService` protocol (`MockPaymentService` live now, `AstraPayPaymentService` stub documenting the real Authorization → Push to Payment → Transaction Status flow)
- **Insight Dashboard** — transactions, pings, conversion rate, busiest hour/area — all computed live from Firestore, no separate analytics backend
- **AstraPoints simulation** — the loyalty hook that ties a purchase back to the AstraPay ecosystem
- **Cross-device real-time sync** — exercised on multiple physical iPhones, each signed into a different seeded account, over one shared Firebase project

---

## How It Works

### Customer Surface (Discover → Pay)

```
[Live Map] ──(tap pin)──▶ [Merchant Detail + Menu] ──(select items)──▶ [Ping]
                                                                           │
                                                          WRITE pings/{id} status=.active
                                                                           ▼
                                                     merchant Accepts ──▶ .onTheWay
                                                                           │
                                                                           ▼
                                                        [Chat] ──▶ meet offline
                                                                           │
                                                                           ▼
                                                [Pay via QRIS] ──(mocked)──▶ transactions/{id}
                                                                           │
                                                                           ▼
                                                  [AstraPoints] + ping ──▶ .completed
```

### Merchant Surface (Keliling Mode → Insight)

```
[Keliling Mode ON] ──▶ WRITE presence.isVisible = true + live location
        │
        ▼
appears on Customer Live Map
        │
        ▼
[Ping Inbox / Ping Map] ──(Accept)──▶ .onTheWay ──▶ [Chat] ──▶ meet offline
        │
        ▼
[Receive Payment] ◀── customer WRITES transactions/{id}
        │
        ▼
[Dashboard / Insight] updates live
        │
        ▼
[Keliling Mode OFF] ──▶ presence.isVisible = false, vendor vanishes from map
```

The two surfaces never call into each other directly — Firestore is the only channel between them.

---

## Data Contract (Firestore)

Swift property names match Firestore field names exactly; this is the contract both surfaces build against.

| Collection | Written by | Read by | Purpose |
|---|---|---|---|
| `users/{uid}` | Auth signup / seed | both | role routing (`.customer` \| `.merchant`) |
| `customers/{uid}` | Customer | Customer, Merchant (denormalized name) | profile, balance, favorites |
| `merchants/{uid}` | Merchant | Customer, Merchant | static profile: name, category, `qrPayload` |
| `merchants/{uid}/presence/live` | Merchant | Customer (Live Map), Merchant | Keliling Mode — fast-changing live location, kept separate so GPS ticks don't trigger profile listeners |
| `merchants/{uid}/menu/{itemId}` | Merchant | Customer | menu items the customer picks from before pinging |
| `pings/{pingId}` | Customer | Merchant | demand signal: `.active → .onTheWay → .completed / .cancelled` |
| `chats/{customerUid}_{merchantUid}` + `messages` | both | both | deterministic 1:1 coordination thread, opened by a ping |
| `transactions/{txnId}` | payment layer (mocked) | Merchant dashboard | recorded QRIS payment, drives the Insight cards |

---

## Roles

| Role | Surface | Core Screens |
|---|---|---|
| Customer | AstraPay App (buyer) | Live Map, Merchant Detail, Ping Status, Chat, Payment, Rewards |
| Merchant | AstraPay Merchant (PKL) | Keliling Mode, Ping Inbox, Ping Map, Chat, Receive Payment, Dashboard, Merchant Profile |

> Team split: Customer surface is Revan's, Merchant surface is Rasya's.

---

## Notes on Scope

- **Payment is fully mocked, by design.** Live AstraPay/QRIS credentials require non-self-serve UAT approval and a backend to hold the client secret — out of hackathon scope. `MockPaymentService` writes a real `transactions` doc so the dashboard updates live; `AstraPayPaymentService` is a stub documenting the production Authorization → Push to Payment → Transaction Status flow.
- **iOS-first is a deliberate scoping decision**, not a limitation — it targets an iPhone-heavy demographic within the hackathon window. Firebase acts as a shared API gateway, so an Android client can be added later without changing the backend contract.
- **Insights stay aggregate.** No per-individual tracking; a merchant's live location is only shared while Keliling Mode is on.

---

## Requirements

| Requirement | Details |
|---|---|
| iPhone | iOS 17.0+ |
| Xcode | 15+ |
| Firebase project | Email/Password Auth enabled, Cloud Firestore + Cloud Storage created |
| `GoogleService-Info.plist` | Firebase config file, gitignored, added to the app target |
| Devices | Multiple physical iPhones recommended for the real two-sided demo (customer pings → merchant's phone receives it live) |

---

## Tech Stack

- **SwiftUI** — UI, iOS 17 `Map` API
- **Swift Concurrency + Combine** — `async/await` for one-shot reads/writes, Combine for live Firestore listeners
- **Firebase Auth** — Email/Password; role is authoritative from `users/{uid}.role`, never a local toggle
- **Cloud Firestore** — realtime sync backbone across devices, via snapshot listeners
- **Cloud Storage** — `photoUrl` / `bannerUrl` download URLs
- **MapKit** — Live Map (Customer) and Ping Map (Merchant)
- **CoreLocation** — user position, and live merchant location while visible
- **Geohash + `CLLocation.distance(from:)`** — candidate filtering by geohash bounds, refined with precise distance
- **CoreImage (`CIQRCodeGenerator`)** — local QR generation from `merchant.qrPayload`
- **Swift Package Manager** — Firebase iOS SDK

---

## Project Structure

```
AstraLing/
├── AstraLingApp.swift          @main — FirebaseApp.configure(), injects services, shows ContentView
├── ContentView.swift            root router (reads auth + role → picks a surface)
├── RoleSelectionView.swift      unauthenticated entry: login (seeded accounts) + DEBUG seed button
├── GoogleService-Info.plist     Firebase config (gitignored — never commit)
├── Assets.xcassets
├── Components/                  reusable SwiftUI views
│   ├── Customer/                customer-only components
│   └── Merchant/                merchant-only components
├── Enums/                       UserRole, PingStatus, TransactionType, TransactionStatus, MenuStatus
├── Models/                      AppUser, Customer, Merchant, MenuItem, Ping, Transaction, Chat, Message
├── Seed/                        MockDataSeeder.swift — the MVP mock-data scope
├── Services/                    Auth, Firestore, Location, Payment(+Mock/+Stub), QR, Storage
├── Utilities/                   Geohash, CLLocation+distance, formatters, extensions
├── ViewModels/
│   ├── Customer/                customer view models
│   └── Merchant/                merchant view models
└── Views/
    ├── Customer/                customer screens
    └── Merchant/                merchant screens
```

---

## Setup

1. Clone the repository
   ```bash
   git clone <your-repo-url>
   cd AstraLing
   ```

2. Open the project in Xcode — Swift Package Manager resolves the Firebase SDK on first open:
   ```bash
   open AstraLing.xcodeproj
   ```

3. Create a Firebase project and add an iOS app to it, then download `GoogleService-Info.plist` and drop it into the project root (it's gitignored, so it won't be committed).

4. In the Firebase Console:
   - Enable **Authentication → Email/Password**
   - Create a **Cloud Firestore** database

5. Build and run. On first launch, `FirebaseApp.configure()` should log a real `projectID`.

6. On `RoleSelectionView`, tap the **DEBUG-only "Seed Mock Data"** button. This calls `MockDataSeeder` and creates 2 merchants + 4 customers (shared seeded password printed to the console), along with their profile docs and each merchant's menu subcollection.

7. For the full two-sided demo, sign into a different seeded account on each device (at least one Customer, at least one Merchant) — merchant turns on Keliling Mode → appears on the customer map → customer pings → merchant's inbox lights up → chat → mock pay → dashboard increments.

---

## Permissions

```
NSLocationWhenInUseUsageDescription — Location access to show nearby vendors and, for merchants, to share live position while Keliling Mode is on
```

---

## License

Built for the **AstraPay Hackathon 2026**. Hackathon prototype — not an official AstraPay product. All rights reserved.
