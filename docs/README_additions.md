
# tj-restock-mvp

Private MVP: Flutter-based iOS app to scan barcodes in-aisle and auto-build a restock pick-list with CSV export.  
**Spec:** see [`docs/spec_v1.1.md`](docs/spec_v1.1.md)

## Quick start (iOS sideload)
1. Install **Xcode** and **Flutter** on a Mac.
2. Plug in iPhone → **Trust this computer** → enable **Settings → Privacy & Security → Developer Mode**.
3. Open `ios/Runner.xcworkspace` in **Xcode** → **Signing & Capabilities**: select your **Personal Team** and set a unique **Bundle ID** (e.g., `com.taylor.tjrestock`).
4. Run (Xcode ▶) or `flutter run -d <your_device>`. Rebuild every 7 days on free provisioning.

## Agent kickoff (one message)
> Work only in brendonsprinkle/tj-restock-mvp (private). Read and follow `docs/spec_v1.1.md`. Create branch `feature/mvp`, implement the MVP per spec, add CI, and open PR “MVP scanning ready (v1.1)”. Post PR link and iPhone run steps.

