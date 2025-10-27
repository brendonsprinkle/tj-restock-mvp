
# Trader Joe’s “Scan-to-Pick-List” App — MVP Technical Requirements & Specification (v1.1)

**Prepared for:** Taylor (Section Lead) & Brendon (Nexus)  
**Target build:** Private MVP for in‑store validation, no App Store distribution  
**Primary devices:** iPhone (personal devices), optional Android later  
**Authoring date:** 2025‑10‑26 (Rev. v1.1 — incorporates Grok review + sections list)

---

## Changelog (v1.1 vs v1.0)
- **Added manual entry as core fallback** when a barcode can’t be read (prevents workflow blocks).
- **Success criteria/KPIs tuned:** ≥90% first‑pass decode (tunable toward 95% with iteration); ≤10% rescan rate.
- **Export hardening:** Share Sheet + **auto‑save CSV** to local Files/Document directory as fallback; offline export test added.
- **Sections seeded in code** from the provided TJ list (see §6.1). UI uses a dropdown/modal selector.
- **Minimal accessibility hooks:** VoiceOver labels for scanner buttons and qty stepper announcements (near‑zero cost).
- **Dependency pinning & abstraction:** Pin `mobile_scanner` ^5.x; define `BarcodeScanner` interface so engines can be swapped.
- **Tests updated** to cover export fallback, manual entry, and rescan KPI capture.

---

## 0. Executive Summary
Replace handwritten restock lists with a **mobile, barcode-driven workflow**: walk a section once, **scan shelf/item barcodes**, and auto-build a **digital pick‑list** grouped by section. Must be **offline‑first**, export **CSV**, and run **without App Store** via local sideloading (free Apple ID provisioning). Manual entry ensures progress when a code can’t be read.

---

## 1. Product Overview

### 1.1 Problem
Section leads/crew handwrite lists on cardboard, then fetch cases. Slow, error‑prone, double‑walking when notes are incomplete.

### 1.2 Solution
A mobile app that converts the aisle walk into **scan events**. Each scan (or manual entry) adds a **PickEntry** with section, barcode/label, and quantity. One‑tap **CSV export** or share action closes the loop.

### 1.3 Success Criteria (MVP)
- Build a complete pick‑list for a 1–2 aisle section **in ≤ 5 minutes** with **≤ 10% rescans** due to misreads.
- **≥ 90%** of target barcodes decode on first pass at typical shelf distance (12–36") in mixed lighting; **goal** to tune toward **≥ 95%** via torch hints and UI tweaks.
- Export usable CSV from the device; **auto‑save** to Files if Share Sheet fails; crew can act on it immediately.
- No network dependency for scanning; all core flows function **offline**.

### 1.4 KPIs
- **Time‑to‑list** (min/section).  
- **Rescan rate** (% of barcodes needing a second attempt) ≤10%.  
- **First‑pass decode rate** (target ≥90%, stretch ≥95%).  
- **Pull accuracy** (items pulled that match exported list).

---

## 2. Scope

### 2.1 In Scope (MVP)
- iOS app (Flutter) with camera-based scan screen.
- Symbologies: **UPC‑A/EAN‑13** (primary), **Code 128** (internal/label), **QR** (future hooks).
- **Manual entry** (“No barcode?” field) to add an item by label/barcode text.
- Section selection (seeded list), per-scan quantity adjustment (+/‑), undo.
- Local data store (Hive or SQLite).
- CSV export via Share Sheet **plus auto‑save fallback** to the app’s Documents directory.
- UI polish: torch toggle, haptic success, duplicate‑scan debounce.
- Sideload on 1–2 personal iPhones via free provisioning.

### 2.2 Out of Scope (MVP)
- Live inventory integration; Auth/SSO; cloud sync/analytics; push notifications.
- Android build (Phase 1b).

### 2.3 Assumptions
- Shelf‑label or package scanning is acceptable for MVP.  
- Personal iPhones allow Developer Mode sideloading.  
- No proprietary SKU data leaves the device beyond user‑initiated CSV shares.

---

## 3. Users & Workflows

### 3.1 Roles
- **Section Lead (Taylor):** sets active section, scans/enters items, exports list.
- **Crew Member:** uses CSV/print to pull cases and stock.

### 3.2 Primary Workflow
1. Choose **Section** (dropdown).  
2. Open **Scanner** → live preview.  
3. **Scan barcode** → app adds **PickEntry** with qty=1.  
4. Adjust **Qty** (+/‑) or **Undo**.  
5. **Pick‑List** → review → **Export CSV** (Share Sheet + auto‑save).  
6. Optionally **Clear After Export**.

### 3.3 Edge Workflows
- **Duplicate scans:** Debounce identical barcode for **1.5 s**; show “already added” chip with quick **+1**.  
- **Bad read / glare:** Torch toggle, re‑center hint, **Manual Entry** button for label/barcode text.  
- **Export issues:** If Share Sheet fails or user cancels, CSV remains **auto‑saved** locally; show “Saved to Files” toast and path.

---

## 4. Non‑Functional Requirements
- **Performance:** Median decode < 300 ms; UI targets 60 fps.  
- **Reliability:** Crash‑free 30‑minute session; safe local persistence.  
- **Offline‑first:** Complete flow works without internet.  
- **Privacy:** No PII, no auto‑uploads; exports are user‑initiated.  
- **Accessibility (minimal):** VoiceOver labels for buttons; announce qty changes; haptic success. (Low effort, no design impact.)  
- **Maintainability:** Clear module boundaries; unit & widget tests.

---

## 5. Technical Architecture

### 5.1 Stack
- **Framework:** Flutter (Dart).  
- **Barcode engine:** Start with `mobile_scanner` **^5.x**. Keep an abstraction to swap to Google ML Kit (`google_mlkit_barcode_scanning`) or a commercial SDK later.  
- **Local DB:** Hive **or** SQLite (`drift`/`sqflite`).  
- **Export:** `csv` + iOS Share Sheet; **also write to** app Documents dir.  
- **Min OS:** iOS **16+** (Developer Mode); Android **10+** (Phase 1b).  
- **CI:** GitHub Actions – format, analyze, test; Android debug artifact.

### 5.2 Scanner Abstraction
Create a simple interface so engines can be swapped without touching UI:
```dart
abstract class BarcodeScanner {
  Stream<ScanResult> results({bool torch});
  Future<void> start();
  Future<void> stop();
}
```
Provide `MobileScannerAdapter` for `mobile_scanner`. Future adapters: `MlKitScannerAdapter`, `ScanditAdapter`.

### 5.3 Logical Components
- `models/` → `Section`, `PickEntry`.  
- `services/` → `scanner_service`, `db_service`, `export_service` (share + autosave), `haptics_service`.  
- `screens/` → `sections_screen`, `scanner_screen`, `picklist_screen`, `manual_entry_sheet`.  
- `state/` → `riverpod` / `provider`.  
- `platform/ios/` → permission string, signing settings.

### 5.4 Data Flow
`Camera → ScannerService → PickEntry → StateStore → DB → UI (PickList) → ExportService (CSV share + autosave)`

---

## 6. Data Model & Seeded Sections

### 6.1 Entities
- **Section**
  - `id: String` (slug)
  - `name: String`
- **PickEntry**
  - `id: String` (uuid)
  - `barcodeOrText: String`  *(barcode value or manual text)*
  - `labelText: String?`
  - `sectionId: String`
  - `qty: int` (default 1)
  - `createdAt: DateTime`

### 6.2 Seeded Sections (initial list)
```
Dry Produce (Dry Pro)
Wet Produce (Wet Pro)
Fresh
Milk/Yogurt (Box)
Meat
Cut Cheeses
Flowers
Coffee & Tea
Cookie & Candy
Snacks
Bread
DFN (Dried Fruit & Nuts)
Beverage
Beer & Wine
HABA (Health & Beauty)
Deli/Dips
Grocery
Frozen
Eggs
```
(Stored as constants; easy to edit in code.)

### 6.3 CSV Export (example)
```
timestamp,section,barcode_or_text,label,qty
2025-10-26T10:22:45-04:00,Grocery,012345678905,"TJ’s Pasta Sauce",2
2025-10-26T10:23:07-04:00,DFN,manual:"Pumpkin Seeds – Salted",1
```

---

## 7. Scanning & UX Spec
- **Scanner screen:** full‑screen preview; torch toggle; haptic on success; **Manual Entry** button.  
- **Debounce:** ignore identical barcode **1.5 s** unless user taps **+1** in a chip.  
- **Section context:** fixed at top; change via dropdown/modal list.  
- **Qty stepper:** quick chip (`– 1 +`) for 2 s; otherwise edit in Pick‑List.  
- **Undo:** snackbar “Added X — Undo” for 2 s.  
- **Pick‑List:** grouped by section; row shows `barcode_or_text | labelText | qty`; swipe to delete; inline qty edit.  
- **Export:** “Export CSV” → Share Sheet; **also auto‑save** to Files (path shown); “Clear after export” option.  
- **Accessibility (minimal):** semantics labels (“Scan”, “Toggle torch”, “Increase quantity”), announce qty changes.

---

## 8. Permissions & Privacy
- **iOS:** `NSCameraUsageDescription` (“Scan barcodes to build your restock list”).  
- No location/contacts/analytics.  
- No network calls except user‑initiated Share Sheet; CSV also saved locally.

---

## 9. Build, Signing, Local Install (No Store)
Same as v1.0: Xcode + Flutter; Developer Mode; Personal Team signing; 7‑day free provisioning renewal.

---

## 10. Testing Strategy

### 10.1 Unit & Widget
- **CSV serialization** and **export fallback path** (file saved).  
- **State store** add/edit/delete.  
- **Debounce** logic.  
- **Manual entry** flow (adds item; appears in export).

### 10.2 Bench / Field Tests
- **Lighting matrix:** bright/ambient/low; torch on/off.  
- **Distance matrix:** 6", 12", 24", 36".  
- **Label types:** shelf vs package; glossy/matte; curved.  
- **Symbologies:** UPC‑A, EAN‑13, Code 128; a QR for future.  
- **Metrics:** first‑pass decode %, **rescan rate ≤10%**, median decode ms, aisle time.

### 10.3 Acceptance Checklist
- [ ] Scan/enter 20 items with **≥90%** first‑pass success; **≤10%** rescan.  
- [ ] Export via Share Sheet; confirm fallback file exists.  
- [ ] Crash‑free 30‑minute session.  
- [ ] Rebuild after 7 days still works on devices.

---

## 11. CI/CD & Repo Automation
- GitHub Actions: format, analyze, test; upload Android debug APK on pushes to `main`.  
- PR template with test plan + screenshots.

---

## 12. Risks & Mitigations
- **Glare / tiny labels:** torch toggle; move closer; focus guide; **manual entry** fallback.  
- **Duplicate / seasonal codes:** allow alias notes; export shows `barcode_or_text`.  
- **Corporate policy:** keep MVP on personal devices; for pitch, plan Apple Dev Program + TestFlight/MDM.  
- **Performance ceiling:** scanner abstraction for easy engine swap.  
- **Data exposure:** exports stay offline; no cloud sync by default.

---

## 13. Future Enhancements
- Android parity; section presets; voice notes; cloud sync; inventory bridges; analytics dashboard.

---

## 14. License/Compliance
- Flutter + packages under permissive licenses; verify chosen scanner package license.  
- Trials for commercial SDKs reviewed before adoption.

---

## 15. Agent Kickoff (v1.1)
**Read this file (docs/spec_v1.1.md) and implement exactly.**  
Branch: `feature/mvp`. Open PR “MVP scanning ready (v1.1)”. Include README with sideload steps and bench scripts; list how to run on iPhone.
