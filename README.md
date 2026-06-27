# Sober

A dead-simple sobriety tracker you run on your phone. It shows **how many days you've been sober** and a **GitHub-style activity grid** of your whole year.

<p align="center">
  <img src="icons/icon-192.png" width="96" alt="Sober icon" />
</p>

## What it does

- **Big day counter** — your current sober streak, front and center.
- **Daily check-in** — one tap to log that you stayed sober today.
- **Year activity grid** — every sober day lights up green, just like GitHub contributions. Scroll back through previous years.
- **Stats** — current streak, best streak, and total sober days.
- **Works offline** — it's a PWA. Install it to your home screen and it runs with no connection.
- **Private** — all data stays on your device in `localStorage`. Nothing is uploaded anywhere.

## How to use it on your phone

It's a Progressive Web App, so there's no app store needed.

### Option A — host it (recommended)
1. Put these files on any static host (GitHub Pages, Netlify, Vercel, etc.).
2. Open the URL on your phone.
3. **iPhone (Safari):** tap Share → *Add to Home Screen*.
   **Android (Chrome):** tap ⋮ → *Install app* / *Add to Home Screen*.
4. Launch it from your home screen — it opens full-screen like a native app.

#### Deploy to GitHub Pages in 1 minute
In your repo: **Settings → Pages → Build and deployment → Source: Deploy from a branch**, pick this branch and the root folder. Your app will be live at `https://<user>.github.io/<repo>/`.

### Option B — try it locally
```bash
# from the project folder
python3 -m http.server 8000
# then open http://localhost:8000 on the same network from your phone
```

## First run
1. Tap the ⚙ gear and set your **sobriety start date**. Every day from that date counts automatically.
2. That's it. Each day, optionally tap **Check in** to mark you showed up.

## Files
| File | Purpose |
|------|---------|
| `index.html` | App markup |
| `styles.css` | Dark, GitHub-inspired styling |
| `app.js` | Counter, streaks, and the activity grid logic |
| `manifest.json` | PWA metadata (installable to home screen) |
| `service-worker.js` | Offline caching |
| `icons/` | App icons |

No build step, no dependencies, no tracking. Just open it.

## Your data
Everything lives in your browser under the `sober.v1` key. Clearing your browser data or using *Reset all data* in settings wipes it. There's no cloud sync by design.
