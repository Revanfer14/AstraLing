# AstraLing — Project Guide

Native iOS MVP for the **AstraPay Hackathon 2026**. Single Xcode project, **two
roles** (Customer + Merchant) in one app, organized **layer-first MVVM**, backed by
**Firebase Auth + Cloud Firestore + Cloud Storage**.

This is the only `CLAUDE.md` — it is always in context. Three parts:

- **Part 0 — Shared foundation** (applies to all code)
- **Part 1 — Customer surface** (the buyer / payer)
- **Part 2 — Merchant surface** (the PKL / pedagang vendor)

Before editing a role-specific file, jump to that role's part. Before adding *any*
file, check the **routing table in §0.3**. The Firestore schema in **§0.6 is the
contract** — match field names exactly.

---
---

# PART 0 — SHARED FOUNDATION

## 0.1 What AstraLing is

Connects customers with **active mobile street vendors (PKL — Pedagang Kaki Lima)**
in real time. It is a **discovery + trust + payment layer on top of the AstraPay
ecosystem** — NOT a food-delivery app, NOT a maps app.

Core loop = **Ping-to-Pay**:

```
Discover → Ping → (Chat to coordinate) → Meet Offline → Pay via QRIS → Earn Points → Insight
```

Deck framework **TEMU**: **TE**mukan pedagang aktif · **M**ulai ping hingga
pembayaran · **U**ngkap insight & bangun kepercayaan.

Positioning guardrail: the customer still buys **offline** and the vendor still
sells **while roaming** — AstraLing only digitizes the *finding*, the *coordinating*
(ping + chat), and the *paying*. **Do not add** cart, checkout, delivery, or a
second payment provider.

## 0.2 ⚠️ The dual-role rule (shapes everything)

One build ships two separate UIs. The surface a device shows is decided by the
**role of the signed-in account** (`users/{uid}.role`). Testing strategy: install on
several physical iPhones, **sign in to a different seeded account per device** (see
`Seed/`), and exercise the real two-sided flow (customer pings → merchant's phone
receives it) over **one shared Firebase project**.

Therefore:

1. **Customer code and Merchant code never import each other.** Their *only*
   communication channel is **Firestore** (§0.6). Want to call a Merchant view model
   from Customer code? Read/write a Firestore document instead.
2. Anything shared (models, enums, services, components, helpers, seed) lives in a
   role-agnostic layer folder and is used by both.

> Team split: Customer is Revan's surface, Merchant is Rasya's surface.

## 0.3 Folder structure & routing convention (READ BEFORE ADDING FILES)

Layer-first: every top-level folder is a **layer**; `Views/`, `ViewModels/`, and
`Components/` are further split by **role**.

```
AstraLing/
├── AstraLingApp.swift          @main — FirebaseApp.configure(), injects services, shows ContentView
├── ContentView.swift           root router (reads auth + role → picks a surface)
├── RoleSelectionView.swift     unauthenticated entry: login (seeded accounts) + DEBUG seed button
├── GoogleService-Info.plist    Firebase config (gitignored — never commit)
├── Assets.xcassets
├── Components/                 reusable SwiftUI views
│   ├── Customer/               customer-only components
│   └── Merchant/               merchant-only components
├── Enums/                      UserRole, PingStatus, TransactionType, TransactionStatus, MenuStatus
├── Models/                     AppUser, Customer, Merchant, MenuItem, Ping, Transaction, Chat, Message
├── Seed/                       MockDataSeeder.swift  ← the "System: mock …" MVP scope
├── Services/                   Auth, Firestore, Location, Payment(+Mock/+Stub), QR, Storage
├── Utilities/                  Geohash, CLLocation+distance, formatters, extensions
├── ViewModels/
│   ├── Customer/               customer view models
│   └── Merchant/               merchant view models
└── Views/
    ├── Customer/               customer screens
    └── Merchant/               merchant screens
```

**Where does a new file go?**

| The file is… | Put it in… |
|---|---|
| A **Customer** screen (`SomethingView`) | `Views/Customer/` |
| A **Customer** view model (`SomethingViewModel`) | `ViewModels/Customer/` |
| A **Customer-only** reusable view | `Components/Customer/` |
| A **Merchant** screen (`SomethingView`) | `Views/Merchant/` |
| A **Merchant** view model (`SomethingViewModel`) | `ViewModels/Merchant/` |
| A **Merchant-only** reusable view | `Components/Merchant/` |
| A reusable view used by **both** roles | `Components/` |
| A data model (Codable, maps to a Firestore doc) | `Models/` |
| An enum | `Enums/` |
| A service (Auth, Firestore, location, payment, QR, storage) | `Services/` |
| An extension / helper / formatter / Geohash | `Utilities/` |
| Mock / seed data | `Seed/` |
| App entry | `AstraLingApp.swift` |
| The root router | `ContentView.swift` |
| The login / unauthenticated entry | `RoleSelectionView.swift` |

**Naming pairs the layers.** A screen `FooView` in `Views/<Role>/` is backed by
`FooViewModel` in `ViewModels/<Role>/` — keep the base name identical.

## 0.4 Tech stack

| Concern | Choice | Notes |
|---|---|---|
| UI | **SwiftUI** | iOS 17+. Use the iOS 17 `Map` API. |
| Async / reactivity | **Swift Concurrency** + **Combine** | Combine for live Firestore listeners; `async/await` for one-shot reads/writes. |
| Auth | **FirebaseAuth (Email/Password)** | Real accounts. Role comes from `users/{uid}.role`. Must be enabled in Console. |
| DB / realtime sync | **Cloud Firestore** | Backbone of cross-device sync; use snapshot listeners. |
| Images | **Cloud Storage** | `photoUrl` / `bannerUrl` are Storage download URLs. MVP may seed URLs or use placeholders. |
| Maps | **MapKit** | `Map`, `Annotation`, `Marker`, `UserAnnotation`. |
| Location | **CoreLocation** | `CLLocationManager` for user position + (merchant) live updates. |
| Geo queries | **Geohash** (`Utilities/Geohash.swift`) | Stored on `customers`/`merchants` for proximity; the seeder already encodes it. |
| QR | **CoreImage** (`CIQRCodeGenerator`) | Generate QR locally from `merchant.qrPayload`. |
| Push / geofence | **UserNotifications** | **Out of scope for MVP** (future pull-factor). |

Dependencies via **Swift Package Manager** (Firebase iOS SDK).
`GoogleService-Info.plist` must be in the app target and is **gitignored**.

## 0.5 The 3-layer product anatomy (from the deck)

Data flows up, value flows back down. The **Intelligence Layer is computed** from
Firestore data (counts, busiest hour/area, conversion) — no separate analytics
backend.

```
CUSTOMER LAYER (AstraPay App)  Live Map · Merchant Detail · Ping · Chat · QRIS Pay · AstraPoints
MERCHANT LAYER (AstraPay Merchant)  Keliling Mode · Ping Inbox · Ping Map · Chat · Receive Pay · Dashboard
INTELLIGENCE LAYER (derived)  Location · Ping · Transaction · Business Insight
```

## 0.6 Firestore schema — THE CONTRACT (matches the schema diagram)

Swift property names == Firestore field names. Models in `Models/`, enums in
`Enums/`. Use `@DocumentID var id: String?` for the document id (which equals the PK
column below).

### Identity (all keyed by the **same Firebase Auth uid**)

A signed-in user has `users/{uid}` (role) **plus** exactly one profile doc:
`customers/{uid}` **or** `merchants/{uid}`. The uid threads through every FK.

```swift
// users/{uid}
struct AppUser: Codable {
    @DocumentID var id: String?         // == Auth uid
    var role: UserRole                  // .customer | .merchant
    var createdAt: Date
}

// customers/{uid}
struct Customer: Identifiable, Codable {
    @DocumentID var id: String?         // == Auth uid
    var name: String
    var email: String
    var balance: Int                    // rupiah
    var photoUrl: String?               // Cloud Storage URL
    var location: GeoPoint
    var geohash: String
    var locationUpdatedAt: Date
    var favorites: [String]             // FK → merchant uids
    var createdAt: Date
}

// merchants/{uid}
struct Merchant: Identifiable, Codable {
    @DocumentID var id: String?         // == Auth uid
    var name: String
    var email: String
    var balance: Int
    var category: String                // "bakso", "martabak", …
    var description: String?
    var bannerUrl: String?              // Cloud Storage URL
    var qrPayload: String               // e.g. "astraling://pay/{uid}" → encode into QR
    var location: GeoPoint              // current position (meaningful while isVisible)
    var geohash: String
    var locationUpdatedAt: Date
    var isVisible: Bool                 // ⭐ Keliling Mode ON/OFF — drives map visibility
    var createdAt: Date
}
```

### Menu (subcollection of a merchant)

```swift
// merchants/{uid}/menu/{itemId}
struct MenuItem: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var price: Int
    var status: MenuStatus              // .tersedia | .habis
    var photoUrl: String?
    var order: Int                      // display order
}
```

### Ping — demand signal. Customer writes, Merchant reads/updates.

```swift
// pings/{pingId}
struct Ping: Identifiable, Codable {
    @DocumentID var id: String?
    var customerUid: String             // FK → customers
    var merchantUid: String             // FK → merchants
    var customerName: String            // denormalized for the inbox
    var customerLocation: GeoPoint      // so the merchant can navigate
    var interestedItems: [String]       // menu item names the customer wants
    var note: String?
    var status: PingStatus              // .active → .onTheWay → .completed / .cancelled
    var createdAt: Date
    var updatedAt: Date
}
```

### Transaction — recorded payment. Written at pay-time, read by the dashboard.

```swift
// transactions/{txnId}
struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var type: TransactionType           // .payment | .transfer  (MVP uses .payment)
    var displayId: String               // human-readable, e.g. "TRX-20260622-0001"
    var customerUid: String?            // FK → customers (nil for some transfers)
    var merchantUid: String             // FK → merchants
    var customerName: String?
    var amount: Int
    var method: String                  // "QRIS" | "AstraPay"
    var status: TransactionStatus       // .success | .failed
    var failureReason: String?
    var pingId: String?                 // FK → pings (links txn back to the demand)
    var createdAt: Date
}
```

### Chat + Messages — 1:1 conversation, opened by a ping.

`chatId` is **deterministic**: `"{customerUid}_{merchantUid}"`, so both sides compute
the same id. Use a helper in `Utilities/`. The chat doc carries denormalized names +
`lastMessage`/`lastMessageAt` for list previews and links its originating `pingId`.

```swift
// chats/{customerUid}_{merchantUid}
struct Chat: Identifiable, Codable {
    @DocumentID var id: String?         // == "{customerUid}_{merchantUid}"
    var customerUid: String             // FK → customers
    var merchantUid: String             // FK → merchants
    var participantUids: [String]       // [customerUid, merchantUid] — for security rules / queries
    var customerName: String
    var merchantName: String
    var lastMessage: String
    var lastMessageAt: Date
    var pingId: String?                 // FK → pings
}

// chats/{chatId}/messages/{msgId}
struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderUid: String               // FK → users
    var senderRole: UserRole            // .customer | .merchant
    var text: String
    var createdAt: Date
}
```

### Enums (`Enums/`)

```swift
enum UserRole: String, Codable { case customer, merchant }
enum PingStatus: String, Codable { case active, onTheWay = "on_the_way", completed, cancelled }
enum TransactionType: String, Codable { case payment, transfer }
enum TransactionStatus: String, Codable { case success, failed }
enum MenuStatus: String, Codable { case tersedia, habis }
```

### Relationship cheat-sheet
- `users/{uid}` ── same uid ── `customers/{uid}` *or* `merchants/{uid}`
- `merchants/{uid}` 1:N `menu` · `chats/{chatId}` 1:N `messages`
- `pings.customerUid`,`transactions.customerUid`,`chats.customerUid` → `customers`
- `pings.merchantUid`,`transactions.merchantUid`,`chats.merchantUid`,`customers.favorites[]` → `merchants`
- `chats.pingId`,`transactions.pingId` → `pings`

### ⚠️ Schema notes to resolve
- **AstraPoints:** the deck MVP lists "AstraPoints simulation", and `Seed/MockDataSeeder`
  currently writes an `astraPoints` field, **but the schema above has no points field.**
  Decide one: add `astraPoints: Int` to `customers`/`merchants`, or keep AstraPoints as
  a client-side mock. Recommended: add the field so loyalty persists across devices.
- **Seeder drift:** the seeder doesn't yet set `bannerUrl`, `createdAt`, `MenuItem.status`,
  `MenuItem.photoUrl`, or `Customer.photoUrl`. Add them when you touch the seeder so seeded
  docs match these models.

## 0.7 Payment is FULLY MOCKED (intentional and correct)

No live AstraPay integration in the MVP, and there must not be one: UAT credentials
need non-self-serve approval, and a live flow needs a backend to hold the
`ClientSecret` + do OAuth/RSA signing — outside hackathon scope.

- Payments are simulated: balances live in Firestore (`customers.balance` /
  `merchants.balance`); the QR encodes `merchant.qrPayload`.
- On "pay", write a `transactions` doc (`type=.payment`, `status=.success`, generated
  `displayId`) so the merchant dashboard updates live on another device. Optionally
  debit/credit the two balances **in a Firestore batch** for realism. (A real,
  atomic, secure version belongs in a Cloud Function — that's the production story,
  not the demo.)

Protocol with two conformances, swapped by injection (all in `Services/`):

```swift
// Services/PaymentService.swift
protocol PaymentService {
    func qrPayload(for merchant: Merchant) -> String     // = merchant.qrPayload
    func pay(amount: Int, customerUid: String, merchantUid: String,
             method: String, pingId: String?) async throws -> Transaction
}
```
- `Services/MockPaymentService.swift` — writes the transaction (+ optional balance
  batch). Used everywhere now.
- `Services/AstraPayPaymentService.swift` — a **stub** documenting Authorization →
  Push to Payment → Transaction Status + a Cloud Functions proxy. Pitch artifact
  only; do not wire to real endpoints.

Pitch line to keep in comments: any e-wallet works via QRIS, but **only AstraPay
unlocks the AstraLing platform features** — that's the real lock-in.

## 0.8 Auth, identity & routing — `Services/AuthService.swift` + `ContentView.swift`

Role is **authoritative from `users/{uid}.role`**, not a local toggle. The current
user's uid IS the `customerUid` / `merchantUid` used everywhere.

```swift
@MainActor final class AuthService: ObservableObject {
    @Published var uid: String?
    @Published var role: UserRole?

    func restore() async { /* if Auth.currentUser, fetch users/{uid}.role */ }
    func signIn(email: String, password: String) async throws { /* sign in, then load role */ }
    func signOut() throws { try Auth.auth().signOut(); uid = nil; role = nil }
}
```
```swift
// ContentView.swift — root router
struct ContentView: View {
    @EnvironmentObject var auth: AuthService
    var body: some View {
        switch (auth.uid, auth.role) {
        case (_?, .customer): CustomerHomeView()    // Views/Customer/
        case (_?, .merchant): MerchantHomeView()    // Views/Merchant/
        default:              RoleSelectionView()    // not signed in → login
        }
    }
}
```
- `RoleSelectionView` is the unauthenticated entry: email/password login using the
  seeded accounts, plus the **DEBUG-only** "Seed Mock Data" button (calls
  `MockDataSeeder`). Since role follows the account, this is effectively a login
  screen. May cache `uid`/`role` in `@AppStorage` to avoid a launch flash.
- Multi-iPhone demo: each device signs into a different seeded account; the surface
  follows that account's role. All devices share one Firebase project.

## 0.9 Seed data — `Seed/MockDataSeeder.swift`

The "System: mock …" MVP scope. Creates 2 merchants + 4 customers (shared password,
printed to the console), their profile docs, and each merchant's `menu` subcollection.
Triggered by a DEBUG-only button on `RoleSelectionView`. Prereqs in Console:
**Email/Password auth enabled** and Firestore created. See §0.6 schema notes for
fields the seeder should also set.

## 0.10 Conventions & gotchas

- **MVVM**, one `ViewModel` per screen, `@MainActor final class … : ObservableObject`,
  services injected — **never** call `FirebaseFirestore` directly inside a `View`.
- **Live data uses snapshot listeners**, not one-shot gets. Remove listeners in
  `deinit` / `onDisappear`.
- **Identity:** `customerUid` / `merchantUid` are always the Auth uid
  (`auth.uid`). Don't invent device ids.
- **Location permission** requested only on first use (`whenInUse`); add
  `NSLocationWhenInUseUsageDescription`. Privacy posture: location shared only after
  permission; merchant location live only while `isVisible == true`; insights are
  aggregate, never per-individual; no public location history.
- **Radar radius is ±500 m – 1 km.** Query candidates by **geohash bounds**
  (`Utilities/Geohash.swift`) then refine with `CLLocation.distance(from:)`. For the
  small demo dataset, `merchants where isVisible == true` + client-side distance is
  acceptable; geohash is there for scale.
- **chatId is deterministic** (`{customerUid}_{merchantUid}`) — never random.
- Money is `Int` rupiah for the demo. Don't ship as-is.

## 0.11 Build & run

```bash
open AstraLing.xcodeproj   # SPM resolves Firebase on first open
xcodebuild -scheme AstraLing -destination 'platform=iOS Simulator,name=iPhone 15' build
```
First-run checklist: (1) `FirebaseApp.configure()` logs a real `projectID`;
(2) Console → Authentication → Email/Password **enabled**; (3) run the DEBUG seed
button → expect 6 Auth users + `users`/`customers`/`merchants`/`menu` docs in
Firestore. Demo: sign each iPhone into a different account (≥1 customer + ≥1
merchant) → merchant turns on Keliling Mode → appears on customer map → customer
pings → inbox lights up → chat/meet → pay (mock) → dashboard increments.

## 0.12 MVP scope (deck p.18 — build to this)

- **Customer:** entry point · live vendor map · merchant detail · ping merchant ·
  QRIS payment simulation · AstraPoints simulation.
- **Merchant:** entry point · Keliling Mode start/stop · merchant profile · live map
  with pins of customers who pinged · ping inbox · payment-received simulation ·
  basic insight dashboard.
- **System:** mock everything via `Seed/`.
- **Added in your schema (beyond p.18):** 1:1 **chat** (`chats`/`messages`) as the
  coordination layer a ping opens — keep it secondary to the core Ping-to-Pay loop.
- **Success criteria:** (1) customer gets it fast · (2) customer completes
  Discover→Ping→Pay unaided · (3) merchant starts Keliling Mode + receives pings ·
  (4) payment sim feels like real QRIS/AstraPay · (5) dashboard shows real value ·
  (6) AstraPay reads as core.

---
---

# PART 1 — CUSTOMER SURFACE

Files: `Views/Customer/`, `ViewModels/Customer/`, `Components/Customer/`.
**Never import anything Merchant.** Talks to Merchant only via Firestore: **reads**
`merchants` (+ `menu`), **writes** `pings`, **writes** `transactions`, **reads/writes**
`chats`/`messages`. `customerUid` is always `auth.uid`.

Goal: finish **Discover → Ping → (Chat) → Pay** with no instructions (#1, #2).

## Screens

Home is `Views/Customer/CustomerHomeView.swift` (a `TabView`).

| Screen | View | ViewModel |
|---|---|---|
| Live Map (home) | `LiveMapView` | `LiveMapViewModel` |
| Merchant Detail | `MerchantDetailView` | `MerchantDetailViewModel` |
| Ping Status | `PingStatusView` | `PingStatusViewModel` |
| Chat | `ChatView` | `ChatViewModel` |
| Payment | `PaymentView` | `PaymentViewModel` |
| Rewards | `LoyaltyView` | `LoyaltyViewModel` |

Merchant pin → `Components/Customer/MerchantPin.swift`.

### 1. Live Map
Snapshot listener on `merchants where isVisible == true`; refine to ≤ ~1 km in the VM
(geohash bounds for scale, client-side distance for the demo).

```swift
@MainActor final class LiveMapViewModel: ObservableObject {
    @Published var merchants: [Merchant] = []
    private var listener: ListenerRegistration?
    func start() {
        location.requestWhenInUse()
        listener = firestore.listenVisibleMerchants { [weak self] merchants in
            guard let self, let me = self.location.current else { return }
            self.merchants = merchants.filter {
                me.distance(from: CLLocation(latitude: $0.location.latitude,
                                             longitude: $0.location.longitude)) <= 1000
            }
        }
    }
    func stop() { listener?.remove(); listener = nil }
}
```
View (iOS 17 `Map`): `UserAnnotation()` + a `MerchantPin` per merchant (category SF
Symbol + verified/`isVisible` cue); tap → Merchant Detail. Optionally draw a radius
circle to signal "local radar."

### 2. Merchant Detail
Trust layer: name, category, `bannerUrl`, description, and the **menu subcollection**
(`merchants/{uid}/menu` ordered by `order`, showing `status` tersedia/habis). The
customer can select `interestedItems`, then **Ping**. Menu is informational — no cart.

### 3. Ping
Writes one `pings` doc with `status = .active` and the customer's coordinates +
selected items; then listens to that doc:

```swift
func sendPing(to merchant: Merchant, items: [String], note: String?) async throws {
    guard let me = location.current, let merchantUid = merchant.id else { return }
    let now = Date()
    try await firestore.createPing(Ping(
        customerUid: auth.uid!, merchantUid: merchantUid, customerName: myName,
        customerLocation: GeoPoint(latitude: me.coordinate.latitude, longitude: me.coordinate.longitude),
        interestedItems: items, note: note, status: .active, createdAt: now, updatedAt: now))
}
```
`.active` → "Menunggu pedagang…" · `.onTheWay` → "Pedagang menuju ke lokasimu" (offer
**Open Chat**) · `.completed` → done · `.cancelled` → back to map. One active ping per
merchant — don't duplicate.

### 4. Chat
Opens the deterministic chat `"{customerUid}_{merchantUid}"`. Ensure the `chats` doc
exists (create with denormalized names + `pingId` if missing), listen to its
`messages` ordered by `createdAt`, and on send append a `Message`
(`senderRole = .customer`) and update `lastMessage`/`lastMessageAt` on the parent.

### 5. Payment
Mocked via `PaymentService`. Familiar QRIS moment → success.
```swift
let txn = try await payment.pay(amount: total, customerUid: auth.uid!,
                                merchantUid: merchant.id!, method: "QRIS", pingId: activePingId)
// writes transactions/{id} → merchant dashboard updates live; then mark ping .completed
```
QR from `QRCodeGenerator` over `payment.qrPayload(for: merchant)`. On success show
amount + tick; surface AstraPay branding (#4, #6).

### 6. Loyalty / AstraPoints
Mocked. Show points + history. **Note:** schema has no points field yet (§0.6) —
either add `customers.astraPoints` or keep this purely client-side for now.

## Customer flow
```
Sign in (role=customer) → Live Map (listen merchants.isVisible==true)
 → tap pin → Merchant Detail (menu) → pick items → Ping (WRITE pings .active)
 → merchant marks .onTheWay → Chat to coordinate → meet offline
 → Pay (WRITE transactions) → ping .completed
```

## Customer checklist
- [ ] Map makes "nearby roaming vendors" obvious in seconds (#1)
- [ ] First-timer finishes Discover→Ping→Pay unaided (#2)
- [ ] Payment feels like real QRIS/AstraPay (#4)
- [ ] AstraPoints visible as the reason to use AstraPay (#6)
- [ ] No cart / delivery / ordering creep

---
---

# PART 2 — MERCHANT / PEDAGANG SURFACE

Files: `Views/Merchant/`, `ViewModels/Merchant/`, `Components/Merchant/`.
**Never import anything Customer.** Talks to Customer only via Firestore:
**writes/updates** its own `merchants/{uid}` (+ `menu`), **reads + updates** `pings`
where `merchantUid == auth.uid`, **reads** `transactions`, **reads/writes**
`chats`/`messages`. `merchantUid` is always `auth.uid`.

Command center: go visible while selling, see who's asking, navigate to them, chat,
get paid, read simple insight. Hinges on starting Keliling Mode + receiving pings
with zero training (#3) and a dashboard that shows real value (#5).

## Screens

Home is `Views/Merchant/MerchantHomeView.swift` (a `TabView`).

| Screen | View | ViewModel |
|---|---|---|
| Keliling Mode (home) | `KelilingModeView` | `KelilingModeViewModel` |
| Ping Map | `PingMapView` | `PingMapViewModel` |
| Ping Inbox | `PingInboxView` | `PingInboxViewModel` |
| Chat | `ChatView` | `ChatViewModel` |
| Receive Payment | `ReceivePaymentView` | `ReceivePaymentViewModel` |
| Dashboard | `DashboardView` | `DashboardViewModel` |
| Profile | `MerchantProfileView` | `MerchantProfileViewModel` |

### 1. Keliling Mode (the core toggle)
ON = set `merchants/{uid}.isVisible = true` + push live `location`/`geohash`/
`locationUpdatedAt`; OFF = `isVisible = false` and vanish. Presence + privacy switch.

```swift
@MainActor final class KelilingModeViewModel: ObservableObject {
    @Published var isVisible = false
    func toggle(_ on: Bool) async {
        isVisible = on
        if on {
            location.requestWhenInUse(); location.startUpdating()
            location.onUpdate = { [weak self] loc in
                guard let self else { return }
                Task { try? await self.firestore.updateMerchantLocation(
                    self.uid, loc.coordinate,
                    geohash: Geohash.encode(latitude: loc.coordinate.latitude,
                                            longitude: loc.coordinate.longitude)) }
            }
        } else { location.stopUpdating(); location.onUpdate = nil }
        try? await firestore.setMerchantVisible(uid, isVisible: on)
    }
}
```
Throttle location pushes (meaningful-distance change). Make the toggle unmissable and
state obvious (big "Sedang Berjualan" banner) so #3 is instant.

### 2. Ping Inbox
Listener on `pings where merchantUid == auth.uid`, newest first, filtered to
`.active`/`.onTheWay`. Row: `customerName`, rough distance (from `customerLocation`),
`interestedItems`, `note`, time.
```swift
func accept(_ ping: Ping) async { try? await firestore.updatePingStatus(ping.id!, .onTheWay) }
```
Actions: Accept → `.onTheWay` (customer sees "on the way", chat opens); Complete →
`.completed` (after pay); dismiss → `.cancelled`. New pings should be prominent
(badge/sound ok; push is out of scope).

### 3. Ping Map
A pin per customer who pinged (from `customerLocation`) so the vendor knows where to
head; own position is `UserAnnotation`; tap a pin → that ping. Matches "live map
dengan pin lokasi customer yang melakukan ping."

### 4. Chat
Same deterministic chat as the customer side (`"{customerUid}_{merchantUid}"`); listen
to `messages`, send with `senderRole = .merchant`, update `lastMessage`/`lastMessageAt`.

### 5. Receive Payment
Merchant side of the mocked payment: typically **show a QR** (from `merchant.qrPayload`
via `QRCodeGenerator`) and/or see "payment received." The merchant "receives" when the
matching `transactions` doc appears (dashboard listener); show success and mark a
linked ping `.completed`. Keep QRIS/AstraPay branding visible (#4, #6).

### 6. Dashboard / Insight (the value proof)
Intelligence Layer, computed live from this merchant's data — listeners on
`transactions where merchantUid == auth.uid` and the merchant's `pings`. Derive:
```swift
struct InsightSummary {
    var totalTransactions: Int
    var totalRevenue: Int             // sum of successful payments
    var pingsReceived: Int
    var conversionRate: Double        // completed pings / total pings
    var busiestHour: Int?             // mode of createdAt hour
    var busiestAreaLabel: String?     // coarse cluster of customer pings (mock ok)
    var topItem: String?              // from interestedItems / menu
}
```
Render as plain cards: jumlah transaksi, ping masuk, area ramai, jam ramai, performa.
Mock-seed so it looks alive, but it must update when a real (mock) transaction lands
during the pitch. **Insights stay aggregate.**

### 7. Merchant Profile
Editor for this merchant's `merchants/{uid}` (name, category, description, bannerUrl,
qrPayload) and its `menu` subcollection (CRUD `MenuItem`: name, price, status, photoUrl,
order). Saving writes the same docs the customer reads — the vendor's digital identity
/ trust layer.

## Merchant flow
```
Sign in (role=merchant) → Keliling Mode START (WRITE merchants.isVisible=true)
 → push location/geohash → appear on customer maps
 → customer pings → Inbox/Map (LISTEN pings(merchantUid==me))
 → Accept (.onTheWay) → Chat → navigate → meet offline
 → Receive Payment (customer WRITES transactions) → Dashboard increments
 → end shift → Keliling Mode STOP (WRITE merchants.isVisible=false)
```

## Merchant checklist
- [ ] Keliling Mode start/stop is the obvious first action; state unmistakable (#3)
- [ ] Incoming pings show live in both inbox and map (#3)
- [ ] Merchant can accept a ping and see the customer's location (#3)
- [ ] "Payment received" reads as real QRIS/AstraPay (#4)
- [ ] Dashboard shows concrete value: transactions, pings, busy area/hour (#5)
- [ ] Insights aggregate; live location only while Keliling Mode is on (privacy)
```
