# Sober

A dead-simple sobriety tracker. It shows **how many days you've been sober** and a **GitHub-style activity grid** of your whole year.

<p align="center">
  <img src="icons/icon-192.png" width="96" alt="Sober icon" />
</p>

This repo ships the app two ways:

| Version | Where it lives | Best for |
|---------|----------------|----------|
| **Native iOS app** (SwiftUI) | [`ios/`](ios/) | A real iPhone app you build in Xcode and run on your device |
| **Web app** (PWA) | repo root | Try it instantly in any phone browser, installable to the home screen |

Both have the same features and the same dark, GitHub-inspired look.

---

## 📱 Native iOS app (SwiftUI)

A proper iPhone app written in SwiftUI. No third-party dependencies.

### Features
- **Big day counter** — your days sober, front and center
- **One-tap daily check-in** with haptic feedback
- **Year activity grid** — every sober day lights up green, just like GitHub contributions; scroll across years
- **Stats** — current streak, best streak, total sober days
- **Private & offline** — data is stored on-device in `UserDefaults`; nothing leaves your phone

### Build & run
> Requires a Mac with **Xcode 15+**. (iOS apps can only be built on macOS.)

1. Open `ios/Sober/Sober.xcodeproj` in Xcode.
2. Select the **Sober** scheme and a simulator (or your iPhone).
3. If running on a real device: in **Signing & Capabilities**, pick your Apple ID team and change the bundle identifier (`com.sober.app`) to something unique.
4. Press **▶ Run**.

First launch: tap the ⚙ gear and set your **sobriety start date**. Every day from that date counts automatically; you can also tap **Check in** each day.

### Project layout
```
ios/Sober/
├── Sober.xcodeproj
└── Sober/
    ├── SoberApp.swift            App entry point
    ├── ContentView.swift         Main screen (counter, check-in, stats)
    ├── SobrietyStore.swift       Data model: counter, streaks, persistence
    ├── Theme.swift               GitHub-inspired color palette
    ├── Views/
    │   ├── ActivityGridView.swift  The year contribution grid
    │   └── SettingsView.swift       Start date + reset
    └── Assets.xcassets           App icon & accent color
```

---

## 🌐 Web app (PWA)

The original Progressive Web App — zero build step, runs in any browser, installs to your home screen.

### Use it on your phone
1. Host the repo-root files on any static host (GitHub Pages, Netlify, Vercel…). A GitHub Pages workflow is already included (`.github/workflows/deploy.yml`) — enable Pages and it auto-deploys.
2. Open the URL on your phone.
3. **iPhone (Safari):** Share → *Add to Home Screen*. **Android (Chrome):** ⋮ → *Install app*.

### Try it locally
```bash
python3 -m http.server 8000
# open http://localhost:8000
```

### Files
`index.html`, `styles.css`, `app.js`, `manifest.json`, `service-worker.js`, `icons/`

---

## Your data
Everything stays on your device — `UserDefaults` on iOS, `localStorage` on the web. There's no account and no cloud sync by design. *Reset all data* in settings wipes it.
