/* Sober — simple sobriety tracker
 * Data model (localStorage key "sober.v1"):
 *   { startDate: "YYYY-MM-DD" | null, checkins: { "YYYY-MM-DD": true } }
 * A day counts as "sober" if it is on/after startDate and on/before today,
 * OR if it was explicitly checked in.
 */

const STORE_KEY = "sober.v1";
const MS_DAY = 86400000;

/* Milestone thresholds (days) used by the ring's "next milestone". */
const MILESTONES = [7, 14, 30, 60, 90, 180, 270, 365];
/* Badges shown in the achievements row. */
const BADGES = [
  { d: 7,   icon: "🌱", label: "1 week" },
  { d: 30,  icon: "⭐", label: "1 month" },
  { d: 90,  icon: "🔥", label: "90 days" },
  { d: 180, icon: "💪", label: "6 months" },
  { d: 365, icon: "🏆", label: "1 year" },
];

/* ---------- date helpers (all local time) ---------- */
function todayKey() { return toKey(new Date()); }
function toKey(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}
function fromKey(k) {
  const [y, m, d] = k.split("-").map(Number);
  return new Date(y, m - 1, d);
}
function daysBetween(aKey, bKey) {
  return Math.round((fromKey(bKey) - fromKey(aKey)) / MS_DAY);
}

/* ---------- storage ---------- */
function load() {
  const defaults = { startDate: null, checkins: {}, dailySpend: null, dailyHours: null, lastCelebrated: 0 };
  try {
    const raw = localStorage.getItem(STORE_KEY);
    if (raw) return Object.assign(defaults, JSON.parse(raw));
  } catch (e) {}
  return defaults;
}
function save(state) { localStorage.setItem(STORE_KEY, JSON.stringify(state)); }

let state = load();
let viewYear = new Date().getFullYear();

/* ---------- core logic ---------- */
function isSober(key) {
  if (state.checkins[key]) return true;
  if (state.startDate) return key >= state.startDate && key <= todayKey();
  return false;
}

function daysSober() {
  const t = todayKey();
  if (state.startDate && state.startDate <= t) {
    return daysBetween(state.startDate, t) + 1;
  }
  return currentStreak();
}

function bestStreak() {
  const keys = soberKeys();
  if (keys.length === 0) return 0;
  keys.sort();
  let best = 1, run = 1;
  for (let i = 1; i < keys.length; i++) {
    run = daysBetween(keys[i - 1], keys[i]) === 1 ? run + 1 : 1;
    if (run > best) best = run;
  }
  return best;
}

function currentStreak() {
  let count = 0;
  let d = new Date();
  if (!isSober(toKey(d))) d = new Date(Date.now() - MS_DAY);
  while (isSober(toKey(d))) {
    count++;
    d = new Date(d.getTime() - MS_DAY);
  }
  return count;
}

function soberKeys() {
  const set = new Set(Object.keys(state.checkins).filter(k => state.checkins[k]));
  if (state.startDate) {
    const t = todayKey();
    let d = fromKey(state.startDate);
    const end = fromKey(t);
    while (d <= end) {
      set.add(toKey(d));
      d = new Date(d.getTime() + MS_DAY);
    }
  }
  return [...set];
}

function totalDays() {
  return soberKeys().filter(k => k <= todayKey()).length;
}

/* Next milestone above `days`, with the previous threshold for ring progress. */
function nextMilestone(days) {
  let prev = 0;
  for (const m of MILESTONES) {
    if (days < m) return { next: m, prev };
    prev = m;
  }
  // beyond a year: next whole-year mark
  const years = Math.floor(days / 365) + 1;
  return { next: years * 365, prev: (years - 1) * 365 };
}

function milestoneLabel(d) {
  const map = { 7: "1 week", 14: "2 weeks", 30: "1 month", 60: "2 months",
                90: "90 days", 180: "6 months", 270: "9 months", 365: "1 year" };
  if (map[d]) return map[d];
  const years = Math.round(d / 365);
  return years === 1 ? "1 year" : `${years} years`;
}

/* ---------- rendering ---------- */
function renderCounter() {
  const n = daysSober();
  document.getElementById("dayCount").textContent = n;
  document.getElementById("dayLabel").textContent = n === 1 ? "day sober" : "days sober";

  const sinceEl = document.getElementById("sinceText");
  if (state.startDate) {
    const d = fromKey(state.startDate);
    sinceEl.textContent = "since " + d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
  } else {
    sinceEl.textContent = "tap ⚙ to set your start date";
  }

  // progress ring toward the next milestone
  const { next, prev } = nextMilestone(n);
  const progress = Math.max(0, Math.min(1, (n - prev) / (next - prev)));
  const ring = document.getElementById("ringProgress");
  const circ = 2 * Math.PI * 108;
  ring.style.strokeDasharray = `${circ}`;
  ring.style.strokeDashoffset = `${circ * (1 - progress)}`;

  const remaining = next - n;
  const nextEl = document.getElementById("milestoneNext");
  if (n === 0 && !state.startDate) {
    nextEl.innerHTML = "Your journey starts today.";
  } else {
    nextEl.innerHTML = `<b>${remaining}</b> ${remaining === 1 ? "day" : "days"} to <b>${milestoneLabel(next)}</b>`;
  }
}

function renderStats() {
  document.getElementById("statCurrent").textContent = currentStreak();
  document.getElementById("statBest").textContent = bestStreak();
  document.getElementById("statTotal").textContent = totalDays();
}

function renderSavings() {
  const n = daysSober();
  const card = document.getElementById("savingsCard");
  const row = document.getElementById("savingsRow");
  const hasMoney = state.dailySpend != null && state.dailySpend > 0;
  const hasHours = state.dailyHours != null && state.dailyHours > 0;

  if (!hasMoney && !hasHours) {
    card.classList.add("empty");
    row.innerHTML = `<div class="savings-empty">Set a daily figure in <button id="savingsSettingsLink">settings</button> to see the money and time you've reclaimed.</div>`;
    const link = document.getElementById("savingsSettingsLink");
    if (link) link.addEventListener("click", openSettings);
    return;
  }

  card.classList.remove("empty");
  const items = [];
  if (hasMoney) {
    const total = Math.round(n * state.dailySpend);
    items.push(`<div class="savings-item">
      <div class="savings-value">$${total.toLocaleString()}</div>
      <div class="savings-sub">not spent · $${state.dailySpend}/day</div>
    </div>`);
  }
  if (hasHours) {
    const totalH = n * state.dailyHours;
    const days = Math.floor(totalH / 24);
    const hrs = Math.round(totalH % 24);
    const pretty = days > 0 ? `${days}d ${hrs}h` : `${Math.round(totalH)}h`;
    items.push(`<div class="savings-item">
      <div class="savings-value">${pretty}</div>
      <div class="savings-sub">reclaimed · ${state.dailyHours}h/day</div>
    </div>`);
  }
  row.innerHTML = items.join("");
}

function renderMilestones() {
  const n = daysSober();
  const el = document.getElementById("milestones");
  el.innerHTML = BADGES.map(b => `
    <div class="badge ${n >= b.d ? "reached" : ""}" title="${b.label}">
      <div class="badge-icon">${b.icon}</div>
      <div class="badge-label">${b.label}</div>
    </div>`).join("");
}

function renderCheckin() {
  const btn = document.getElementById("checkinBtn");
  const title = document.getElementById("checkinTitle");
  const sub = document.getElementById("checkinSub");
  const done = isSober(todayKey());
  if (done) {
    btn.textContent = "✓ Done";
    btn.classList.add("done");
    title.textContent = "You showed up today";
    sub.textContent = "One more sober day in the books. Keep going.";
  } else {
    btn.textContent = "Check in";
    btn.classList.remove("done");
    title.textContent = "Stay strong today";
    sub.textContent = "Tap to log that you stayed sober today.";
  }
}

function renderGrid() {
  document.getElementById("yearLabel").textContent = viewYear;
  const grid = document.getElementById("grid");
  const monthLabels = document.getElementById("monthLabels");
  grid.innerHTML = "";
  monthLabels.innerHTML = "";

  const jan1 = new Date(viewYear, 0, 1);
  const dec31 = new Date(viewYear, 11, 31);
  const t = todayKey();
  const leadingBlanks = jan1.getDay();

  const daysInYear = Math.round((dec31 - jan1) / MS_DAY) + 1;
  const numCols = Math.ceil((leadingBlanks + daysInYear) / 7);

  // Size cells (and gap) to fit the whole year across the card width — no scroll.
  const avail = grid.parentElement.clientWidth || (document.querySelector(".grid-card").clientWidth - 32);
  const gapsTotal = numCols - 1;
  // first pass: estimate cell, then scale the gap to it, then recompute
  let cell = Math.floor((avail - gapsTotal * 2) / numCols);
  let gap = Math.max(1, Math.min(3, Math.round(cell / 4)));
  cell = Math.floor((avail - gapsTotal * gap) / numCols);
  cell = Math.max(3, Math.min(cell, 15));
  // safety: shrink until the row fits with no overflow
  while (numCols * cell + gapsTotal * gap > avail && cell > 3) cell--;
  document.documentElement.style.setProperty("--cell", cell + "px");
  document.documentElement.style.setProperty("--cell-gap", gap + "px");
  const pitch = cell + gap;

  for (let i = 0; i < leadingBlanks; i++) {
    const c = document.createElement("div");
    c.className = "cell empty";
    grid.appendChild(c);
  }

  const monthCols = {};
  let dayIndex = leadingBlanks;
  let soberThisYear = 0;

  for (let d = new Date(jan1); d <= dec31; d = new Date(d.getTime() + MS_DAY)) {
    const key = toKey(d);
    const col = Math.floor(dayIndex / 7);
    const month = d.getMonth();
    if (monthCols[month] === undefined) monthCols[month] = col;

    const c = document.createElement("div");
    c.className = "cell";
    if (key <= t && isSober(key)) { c.classList.add("l4"); soberThisYear++; }
    if (key === t) c.classList.add("today");
    grid.appendChild(c);
    dayIndex++;
  }

  const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  Object.entries(monthCols).forEach(([m, col]) => {
    // skip a label if it would overlap the previous month's (very small cells)
    const span = document.createElement("span");
    span.textContent = monthNames[m];
    span.style.left = (col * pitch) + "px";
    monthLabels.appendChild(span);
  });

  const countEl = document.getElementById("gridCount");
  if (countEl) {
    countEl.textContent = `${soberThisYear} sober ${soberThisYear === 1 ? "day" : "days"} in ${viewYear}`;
  }
}

function renderAll() {
  renderCounter();
  renderStats();
  renderSavings();
  renderMilestones();
  renderCheckin();
  renderGrid();
  maybeCelebrate();
}

/* Fire confetti when a new badge milestone is reached (once per milestone). */
function maybeCelebrate() {
  const n = daysSober();
  const reached = BADGES.filter(b => n >= b.d).map(b => b.d);
  const highest = reached.length ? Math.max(...reached) : 0;
  if (highest > (state.lastCelebrated || 0)) {
    state.lastCelebrated = highest;
    save(state);
    const badge = BADGES.find(b => b.d === highest);
    burstConfetti();
    toast(`${badge.icon} ${badge.label} milestone! Incredible.`);
  }
}

/* ---------- confetti (lightweight, no deps) ---------- */
function burstConfetti() {
  const canvas = document.getElementById("confetti");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  const dpr = window.devicePixelRatio || 1;
  canvas.width = window.innerWidth * dpr;
  canvas.height = window.innerHeight * dpr;
  ctx.scale(dpr, dpr);
  canvas.classList.add("active");

  const W = window.innerWidth, H = window.innerHeight;
  const colors = ["#39d353", "#2ea043", "#26a641", "#e6edf3", "#0e4429"];
  const N = 140;
  const parts = Array.from({ length: N }, () => ({
    x: W / 2 + (Math.random() - 0.5) * W * 0.3,
    y: H * 0.32,
    vx: (Math.random() - 0.5) * 9,
    vy: Math.random() * -11 - 5,
    s: 5 + Math.random() * 6,
    rot: Math.random() * Math.PI,
    vr: (Math.random() - 0.5) * 0.3,
    c: colors[(Math.random() * colors.length) | 0],
    life: 1,
  }));

  let frame = 0;
  function tick() {
    ctx.clearRect(0, 0, W, H);
    frame++;
    let alive = false;
    for (const p of parts) {
      p.vy += 0.32;          // gravity
      p.vx *= 0.99;
      p.x += p.vx;
      p.y += p.vy;
      p.rot += p.vr;
      if (frame > 60) p.life -= 0.018;
      if (p.life > 0 && p.y < H + 40) {
        alive = true;
        ctx.save();
        ctx.globalAlpha = Math.max(0, p.life);
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot);
        ctx.fillStyle = p.c;
        ctx.fillRect(-p.s / 2, -p.s / 2, p.s, p.s * 0.6);
        ctx.restore();
      }
    }
    if (alive) {
      requestAnimationFrame(tick);
    } else {
      ctx.clearRect(0, 0, W, H);
      canvas.classList.remove("active");
    }
  }
  requestAnimationFrame(tick);
}

/* ---------- interactions ---------- */
function toast(msg) {
  const el = document.getElementById("toast");
  el.textContent = msg;
  el.classList.remove("hidden");
  clearTimeout(el._t);
  el._t = setTimeout(() => el.classList.add("hidden"), 1800);
}

document.getElementById("checkinBtn").addEventListener("click", () => {
  const key = todayKey();
  if (isSober(key)) {
    state.checkins[key] = true;
    save(state);
    renderAll();
    toast("Already counted today 💪");
    return;
  }
  state.checkins[key] = true;
  if (!state.startDate) state.startDate = key;
  save(state);
  renderAll();
  toast("Logged today. Proud of you. 🌱");
});

const modal = document.getElementById("settingsModal");
function openSettings() {
  document.getElementById("startDateInput").value = state.startDate || "";
  document.getElementById("dailySpendInput").value = state.dailySpend ?? "";
  document.getElementById("dailyHoursInput").value = state.dailyHours ?? "";
  modal.classList.remove("hidden");
}
document.getElementById("settingsBtn").addEventListener("click", openSettings);
document.getElementById("closeSettings").addEventListener("click", () => modal.classList.add("hidden"));
modal.addEventListener("click", (e) => { if (e.target === modal) modal.classList.add("hidden"); });

document.getElementById("dailySpendInput").addEventListener("input", (e) => {
  const v = parseFloat(e.target.value);
  state.dailySpend = isNaN(v) || v < 0 ? null : v;
  save(state);
  renderSavings();
});
document.getElementById("dailyHoursInput").addEventListener("input", (e) => {
  const v = parseFloat(e.target.value);
  state.dailyHours = isNaN(v) || v < 0 ? null : v;
  save(state);
  renderSavings();
});

document.getElementById("startDateInput").addEventListener("change", (e) => {
  const v = e.target.value;
  if (!v) return;
  if (v > todayKey()) { toast("Start date can't be in the future"); e.target.value = state.startDate || ""; return; }
  state.startDate = v;
  save(state);
  viewYear = new Date().getFullYear();
  renderAll();
  toast("Start date saved");
});

document.getElementById("resetBtn").addEventListener("click", () => {
  if (confirm("Reset all data? This can't be undone.")) {
    state = { startDate: null, checkins: {} };
    save(state);
    viewYear = new Date().getFullYear();
    renderAll();
    modal.classList.add("hidden");
    toast("Data reset");
  }
});

document.getElementById("prevYear").addEventListener("click", () => { viewYear--; renderGrid(); });
document.getElementById("nextYear").addEventListener("click", () => {
  if (viewYear < new Date().getFullYear() + 1) { viewYear++; renderGrid(); }
});

/* Re-fit the grid when the viewport width changes. */
let resizeTimer;
window.addEventListener("resize", () => {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(renderGrid, 120);
});

/* ---------- init ---------- */
renderAll();

/* ---------- PWA service worker ---------- */
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js").catch(() => {});
  });
}
