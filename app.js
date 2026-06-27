/* Sober — simple sobriety tracker
 * Data model (localStorage key "sober.v1"):
 *   { startDate: "YYYY-MM-DD" | null, checkins: { "YYYY-MM-DD": true } }
 * A day counts as "sober" if it is on/after startDate and on/before today,
 * OR if it was explicitly checked in. The grid colors days by that status.
 */

const STORE_KEY = "sober.v1";
const MS_DAY = 86400000;

/* ---------- date helpers (all local time, no timezone surprises) ---------- */
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
  // whole days from a -> b (b - a), based on local midnight
  return Math.round((fromKey(bKey) - fromKey(aKey)) / MS_DAY);
}

/* ---------- storage ---------- */
function load() {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {}
  return { startDate: null, checkins: {} };
}
function save(state) {
  localStorage.setItem(STORE_KEY, JSON.stringify(state));
}

let state = load();
let viewYear = new Date().getFullYear();

/* ---------- core logic ---------- */
// Is this date key considered a sober day?
function isSober(key) {
  if (state.checkins[key]) return true;
  if (state.startDate) {
    return key >= state.startDate && key <= todayKey();
  }
  return false;
}

// Days sober counter: continuous run ending today.
function daysSober() {
  const t = todayKey();
  if (state.startDate && state.startDate <= t) {
    return daysBetween(state.startDate, t) + 1; // inclusive of start day
  }
  // fall back to current streak of check-ins ending today/yesterday
  return currentStreak();
}

// Longest run of consecutive sober days across all data.
function bestStreak() {
  const keys = soberKeys();
  if (keys.length === 0) return 0;
  keys.sort();
  let best = 1, run = 1;
  for (let i = 1; i < keys.length; i++) {
    if (daysBetween(keys[i - 1], keys[i]) === 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
  }
  return best;
}

// Streak of consecutive sober days ending today (or yesterday).
function currentStreak() {
  let count = 0;
  let d = new Date();
  // if today not yet sober, allow streak to end yesterday
  if (!isSober(toKey(d))) d = new Date(Date.now() - MS_DAY);
  while (isSober(toKey(d))) {
    count++;
    d = new Date(d.getTime() - MS_DAY);
  }
  return count;
}

// All sober day keys (checkins + the start-date range up to today).
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

/* ---------- rendering ---------- */
function renderCounter() {
  const n = daysSober();
  document.getElementById("dayCount").textContent = n;
  document.getElementById("dayLabel").textContent = n === 1 ? "day sober" : "days sober";
  const sinceEl = document.getElementById("sinceText");
  if (state.startDate) {
    const d = fromKey(state.startDate);
    sinceEl.textContent = "since " + d.toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" });
  } else {
    sinceEl.textContent = "Set your start date in settings ⚙";
  }
}

function renderStats() {
  document.getElementById("statCurrent").textContent = currentStreak();
  document.getElementById("statBest").textContent = bestStreak();
  document.getElementById("statTotal").textContent = totalDays();
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

  // Pad start so column 0 begins on Sunday.
  const leadingBlanks = jan1.getDay(); // 0 = Sun
  for (let i = 0; i < leadingBlanks; i++) {
    const cell = document.createElement("div");
    cell.className = "cell empty";
    grid.appendChild(cell);
  }

  const monthCols = {}; // month -> first column index
  let dayIndex = leadingBlanks;

  for (let d = new Date(jan1); d <= dec31; d = new Date(d.getTime() + MS_DAY)) {
    const key = toKey(d);
    const col = Math.floor(dayIndex / 7);
    const month = d.getMonth();
    if (monthCols[month] === undefined) monthCols[month] = col;

    const cell = document.createElement("div");
    cell.className = "cell";
    if (key <= t && isSober(key)) {
      cell.classList.add("l4"); // sober = strong green
    }
    if (key === t) cell.classList.add("today");
    cell.title = fromKey(key).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric", year: "numeric" })
      + (isSober(key) && key <= t ? " · sober" : "");
    grid.appendChild(cell);
    dayIndex++;
  }

  // Month labels positioned by column.
  const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  const colWidth = 11 + 3; // cell + gap
  Object.entries(monthCols).forEach(([m, col]) => {
    const span = document.createElement("span");
    span.textContent = monthNames[m];
    span.style.left = (col * colWidth) + "px";
    monthLabels.appendChild(span);
  });
}

function renderAll() {
  renderCounter();
  renderStats();
  renderCheckin();
  renderGrid();
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
  if (state.checkins[key] || (state.startDate && key >= state.startDate)) {
    // already counted via start date — make sure it's explicitly stored too
    if (!isSober(key)) {
      state.checkins[key] = true;
    }
    // If start date already covers today, nothing to toggle off; just acknowledge.
    if (!state.checkins[key]) state.checkins[key] = true;
    save(state);
    renderAll();
    toast("Already counted today 💪");
    return;
  }
  state.checkins[key] = true;
  if (!state.startDate) state.startDate = key; // first ever check-in seeds the start
  save(state);
  renderAll();
  toast("Logged today. Proud of you. 🌱");
});

const modal = document.getElementById("settingsModal");
document.getElementById("settingsBtn").addEventListener("click", () => {
  document.getElementById("startDateInput").value = state.startDate || "";
  modal.classList.remove("hidden");
});
document.getElementById("closeSettings").addEventListener("click", () => modal.classList.add("hidden"));
modal.addEventListener("click", (e) => { if (e.target === modal) modal.classList.add("hidden"); });

document.getElementById("startDateInput").addEventListener("change", (e) => {
  const v = e.target.value;
  if (!v) return;
  if (v > todayKey()) { toast("Start date can't be in the future"); e.target.value = state.startDate || ""; return; }
  state.startDate = v;
  save(state);
  viewYear = fromKey(v).getFullYear() > viewYear ? viewYear : new Date().getFullYear();
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

/* ---------- init ---------- */
renderAll();
// Scroll grid so today's column is comfortably in view (not the empty year-end).
requestAnimationFrame(() => {
  const sc = document.querySelector(".grid-scroll");
  if (!sc) return;
  const todayCell = sc.querySelector(".cell.today");
  if (todayCell) {
    const target = todayCell.offsetLeft - sc.clientWidth * 0.6;
    sc.scrollLeft = Math.max(0, target);
  } else {
    sc.scrollLeft = sc.scrollWidth;
  }
});

/* ---------- PWA service worker ---------- */
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js").catch(() => {});
  });
}
