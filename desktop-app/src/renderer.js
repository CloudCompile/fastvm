'use strict';

/**
 * FastVM Marketplace frontend.
 *
 * Talks to the Rust backend through Tauri's `invoke` bridge (exposed on
 * `window.__TAURI__` via `withGlobalTauri`). No Node or filesystem access.
 *
 * The `docker run` preview is produced by the backend (`preview_run_args`) so it
 * can never drift from what a deploy actually executes.
 */

const { invoke } = window.__TAURI__.core;
const { openUrl } = window.__TAURI__.opener;

const $ = (id) => document.getElementById(id);

let APPS = [];
let FILTER = 'All';
let SELECTED = null;
let DOCKER_OK = false;
let HOST_GPU = { present: false, vendor: 'none', render_node: null, devices: [], modes: ['off'], encoders: ['software'], recommended: 'off', toolkit: false, kfd: false };
let LAST_CMD = '';
let INSTANCES_TIMER = null;
let LOGS_TIMER = null;
let PREVIEW_SEQ = 0;
let SORT = 'featured';
let FAVORITES = new Set();
let LAST_INSTANCES = [];
let STATS = {};

const INSTANCES_REFRESH_MS = 5000;
const LOGS_REFRESH_MS = 3000;
const FAVORITES_KEY = 'fastvm.favorites';

const CATEGORY_ORDER = [
  'Featured', 'Desktops', 'Gaming', 'Development', 'Content Creation',
  'Office', 'Security', 'Distros', 'Minimal', 'All',
];

const RAM_MB = (s) => {
  const m = /([\d.]+)\s*(GB|MB)/i.exec(String(s || ''));
  if (!m) return 99999;
  const n = parseFloat(m[1]);
  return /gb/i.test(m[2]) ? n * 1024 : n;
};

function toast(message, isError) {
  const el = $('toast');
  el.textContent = message;
  el.className = 'toast' + (isError ? ' err' : '');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => el.classList.add('hidden'), 3200);
}

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, (ch) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]
  ));
}

async function copyText(text, label) {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
    } else {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      ta.remove();
    }
    toast(`${label} copied`);
  } catch (err) {
    toast(`Copy failed: ${err}`, true);
  }
}

// ----------------------------------------------------------------- favorites

function loadFavorites() {
  try {
    const raw = window.localStorage && window.localStorage.getItem(FAVORITES_KEY);
    if (raw) FAVORITES = new Set(JSON.parse(raw));
  } catch { /* ignore malformed or unavailable storage */ }
}

function saveFavorites() {
  try {
    if (window.localStorage) window.localStorage.setItem(FAVORITES_KEY, JSON.stringify([...FAVORITES]));
  } catch { /* ignore */ }
}

function toggleFavorite(id) {
  if (FAVORITES.has(id)) FAVORITES.delete(id);
  else FAVORITES.add(id);
  saveFavorites();
  renderGrid();
}

// -------------------------------------------------------------------- status

function renderGpuStatus() {
  const el = $('gpu-status');
  if (HOST_GPU.present) {
    const vendor = HOST_GPU.vendor && HOST_GPU.vendor !== 'none' ? HOST_GPU.vendor : 'GPU';
    const modes = (HOST_GPU.modes || []).filter((m) => m !== 'off').map((m) => m.toUpperCase());
    el.textContent = `GPU: ${vendor}${modes.length ? ' · ' + modes[0] : ''}`;
    el.title = 'Click for GPU details';
    el.className = 'status ok';
  } else {
    el.textContent = 'No GPU';
    el.title = 'No /dev/dri graphics device detected on this host';
    el.className = 'status';
  }
}

function showGpuDetails() {
  if (!HOST_GPU.present) {
    toast('No graphics device detected on this host', true);
    return;
  }
  const modes = (HOST_GPU.modes || []).map((m) => m.toUpperCase()).join(', ');
  const lines = [
    `Vendor: ${HOST_GPU.vendor}`,
    HOST_GPU.render_node ? `Render node: ${HOST_GPU.render_node}` : 'Render node: (none)',
    `Acceleration modes: ${modes}`,
    `Encoders: ${(HOST_GPU.encoders || ['software']).join(', ')}`,
    `ROCm compute (/dev/kfd): ${HOST_GPU.kfd ? 'present' : 'absent'}`,
    `NVIDIA container toolkit: ${HOST_GPU.toolkit ? 'present' : 'not detected'}`,
  ];
  for (const d of HOST_GPU.devices || []) {
    const driver = d.driver ? ` (${d.driver})` : '';
    const vram = d.vram_bytes ? ` · ${formatBytes(d.vram_bytes)}` : '';
    lines.push(`  • ${d.node}: ${d.vendor}${driver}${vram}`);
  }
  if (HOST_GPU.compute_only) {
    lines.push('Compute-only accelerator: no graphics engine — desktop renders on CPU');
  }
  toast(lines.join('  •  '));
}

function formatBytes(n) {
  if (!n) return '';
  const gb = n / 1024 ** 3;
  return gb >= 1 ? `${gb.toFixed(1)} GB VRAM` : `${Math.round(n / 1024 ** 2)} MB VRAM`;
}

/// Show, in a modal, the in-container commands that prove the selected GPU mode
/// is working. The list is produced by the Rust backend (`gpu_verify`).
async function showGpuVerify() {
  const mode = ($('gpu-mode') && $('gpu-mode').value) || 'off';
  let steps;
  try {
    steps = await invoke('gpu_verify', { mode });
  } catch (err) {
    toast(`Could not load verification steps: ${err}`, true);
    return;
  }
  openModal(
    `Verify GPU (${gpuModeLabel(mode)})`,
    `<p class="hint">Run these inside the container to confirm the GPU is in use:</p>
     <pre class="verify">${steps.map(escapeHtml).join('\n')}</pre>
     <p class="hint">Tip: <code>docker exec -it &lt;container&gt; bash</code> first.</p>`,
  );
}

// -------------------------------------------------------------------- catalog

function renderTabs() {
  const cats = new Set(APPS.map((a) => a.category));
  const tabs = CATEGORY_ORDER.filter((c) => {
    if (c === 'All') return true;
    if (c === 'Featured') return APPS.some((a) => a.featured) || FAVORITES.size > 0;
    return cats.has(c);
  });
  const nav = $('tabs');
  nav.innerHTML = '';
  for (const cat of tabs) {
    const b = document.createElement('button');
    b.className = 'tab' + (FILTER === cat ? ' active' : '');
    b.textContent = cat;
    b.setAttribute('role', 'tab');
    b.setAttribute('aria-selected', FILTER === cat ? 'true' : 'false');
    b.addEventListener('click', () => { FILTER = cat; renderTabs(); renderGrid(); });
    nav.appendChild(b);
  }
}

function visibleApps() {
  const q = $('search').value.trim().toLowerCase();
  let apps = APPS.filter((a) => {
    const inFilter = FILTER === 'All'
      || (FILTER === 'Featured' ? (a.featured || FAVORITES.has(a.id)) : a.category === FILTER);
    const inSearch = !q
      || a.name.toLowerCase().includes(q)
      || a.tagline.toLowerCase().includes(q)
      || a.id.toLowerCase().includes(q)
      || a.category.toLowerCase().includes(q);
    return inFilter && inSearch;
  });
  apps = apps.slice().sort((a, b) => {
    if (SORT === 'name') return a.name.localeCompare(b.name);
    if (SORT === 'ram') return RAM_MB(a.ram) - RAM_MB(b.ram);
    // Featured: starred/favorites first, then featured, then name.
    const score = (x) => (FAVORITES.has(x.id) ? 2 : 0) + (x.featured ? 1 : 0);
    return score(b) - score(a) || a.name.localeCompare(b.name);
  });
  return apps;
}

function renderGrid() {
  const grid = $('grid');
  const apps = visibleApps();
  grid.innerHTML = '';
  $('no-results').classList.toggle('hidden', apps.length > 0);
  $('result-count').textContent = apps.length ? `${apps.length} of ${APPS.length} images` : '';
  for (const a of apps) {
    const fav = FAVORITES.has(a.id);
    const card = document.createElement('div');
    card.className = 'card' + (SELECTED && SELECTED.id === a.id ? ' selected' : '');
    card.setAttribute('role', 'listitem');
    card.tabIndex = 0;
    card.dataset.id = a.id;
    card.innerHTML = `
      <div class="head">
        <span class="title">${escapeHtml(a.name)}</span>
        <span class="head-right">
          <button class="star ${fav ? 'on' : ''}" data-id="${escapeHtml(a.id)}" title="${fav ? 'Unstar' : 'Star'}" aria-label="Toggle favorite" aria-pressed="${fav}">${fav ? '★' : '☆'}</button>
          ${a.featured ? '<span class="chip featured">★</span>' : ''}
        </span>
      </div>
      <div class="tagline">${escapeHtml(a.tagline)}</div>
      <div class="foot">
        <span class="chip">${escapeHtml(a.category)}</span>
        <span class="chip">${escapeHtml(a.ram)} RAM</span>
        ${a.gpu ? '<span class="chip gpu">GPU</span>' : ''}
      </div>
      <button class="install" data-id="${escapeHtml(a.id)}">Deploy</button>`;
    card.addEventListener('click', (e) => {
      if (e.target.classList.contains('install') || e.target.classList.contains('star')) return;
      select(a);
    });
    card.addEventListener('keydown', (e) => {
      if (e.target !== card) return;
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); select(a); }
    });
    card.querySelector('.install').addEventListener('click', () => select(a, true));
    card.querySelector('.star').addEventListener('click', () => toggleFavorite(a.id));
    grid.appendChild(card);
  }
}

function select(app, deployNow) {
  SELECTED = app;
  renderGrid();
  $('details-empty').classList.add('hidden');
  const body = $('details-body');
  body.classList.remove('hidden');

  const gpuAvailable = HOST_GPU.present;
  const modes = (HOST_GPU.modes || ['off']).filter((m) => m !== 'off');
  const recommended = HOST_GPU.recommended && HOST_GPU.recommended !== 'off'
    ? HOST_GPU.recommended
    : (modes[0] || 'off');
  const modeOptions = ['off', ...modes]
    .map((m) => `<option value="${m}"${(app.gpu && m === recommended) || (!app.gpu && m === 'off') ? ' selected' : ''}>${gpuModeLabel(m)}</option>`)
    .join('');
  const gpuHint = gpuAvailable
    ? `Host: ${escapeHtml(HOST_GPU.vendor)}${modes.length ? ' · ' + modes.map((m) => m.toUpperCase()).join('/') : ''}`
    : 'No /dev/dri on this host';
  // Encoder choices come from the backend (vendor-aware, always ends software).
  const encoders = HOST_GPU.encoders && HOST_GPU.encoders.length ? HOST_GPU.encoders : ['software'];
  const defaultEncoder = {
    nvidia: 'nvenc',
    drm: encoders.includes('qsv') ? 'qsv' : 'vaapi',
    rocm: 'software',
  }[recommended] || 'software';
  const encoderOptions = encoders
    .map((e) => `<option value="${e}"${e === defaultEncoder ? ' selected' : ''}>${encoderLabel(e)}</option>`)
    .join('');
  // The backend computes the warning (toolkit missing, compute-only, …) so the
  // UI never has to re-derive host facts.
  const warn = gpuAvailable && HOST_GPU.warning
    ? `<p class="warn">${escapeHtml(HOST_GPU.warning)}</p>`
    : '';

  body.innerHTML = `
    <h2>${escapeHtml(app.name)}</h2>
    <div class="sub">${escapeHtml(app.tagline)}</div>
    <div class="image-line">
      <code>${escapeHtml(app.image)}</code>
      <button class="ghost tiny" id="copy-image">Copy</button>
    </div>
    <div class="grid2">
      <label class="field"><span>Desktop port</span><input id="host-port" type="number" value="3000" min="1" /></label>
      <label class="field"><span>Dashboard port</span><input id="dash-port" type="number" value="3001" min="0" /></label>
    </div>
    <div class="grid2">
      <label class="field"><span>Container name</span><input id="name" type="text" placeholder="FastVM" /></label>
      <label class="field"><span>Shared memory</span><input id="shm" type="text" value="${app.gpu ? '4gb' : '2gb'}" /></label>
    </div>
    <div class="field">
      <span>GPU acceleration</span>
      <select id="gpu-mode" ${gpuAvailable ? '' : 'disabled'}>${modeOptions}</select>
      <span class="hint">${gpuHint}</span>
      <button class="ghost tiny" id="gpu-verify" ${gpuAvailable ? '' : 'disabled'}>Verify in container</button>
    </div>
    <div class="field">
      <span>Video encoder</span>
      <select id="encoder" ${gpuAvailable ? '' : 'disabled'}>${encoderOptions}</select>
      <span class="hint">Recording/streaming encoder; hardware frees the CPU.</span>
    </div>
    ${warn}
    <details class="advanced">
      <summary>Advanced options</summary>
      <div class="grid2">
        <label class="field"><span>Memory limit</span><input id="memory" type="text" placeholder="e.g. 4g" /></label>
        <label class="field"><span>CPU limit</span><input id="cpus" type="text" placeholder="e.g. 2" /></label>
      </div>
      <label class="field"><span>Environment (one KEY=VALUE per line)</span><textarea id="env" rows="2" placeholder="TZ=Etc/UTC"></textarea></label>
      <label class="field"><span>Volumes (one host:container per line)</span><textarea id="volumes" rows="2" placeholder="/home/me/work:/work"></textarea></label>
    </details>
    <div class="preview-head">
      <span>Command</span>
      <span class="fmt-toggle" role="tablist" aria-label="Preview format">
        <button class="fmt active" id="fmt-run" role="tab" aria-selected="true">docker run</button>
        <button class="fmt" id="fmt-compose" role="tab" aria-selected="false">compose</button>
      </span>
      <button class="ghost tiny" id="copy-cmd">Copy</button>
    </div>
    <div class="preview" id="preview">…</div>
    <button class="primary" id="deploy">⚡ Deploy ${escapeHtml(app.name)}</button>
    <p class="result" id="deploy-result"></p>`;

  for (const id of ['host-port', 'dash-port', 'name', 'shm', 'gpu-mode', 'encoder', 'memory', 'cpus', 'env', 'volumes']) {
    $(id).addEventListener('input', updatePreview);
    $(id).addEventListener('change', updatePreview);
  }
  $('copy-image').addEventListener('click', () => copyText(app.image, 'Image'));
  $('copy-cmd').addEventListener('click', () => copyText(LAST_CMD, 'Command'));
  $('fmt-run').addEventListener('click', () => setFormat('run'));
  $('fmt-compose').addEventListener('click', () => setFormat('compose'));
  $('gpu-verify').addEventListener('click', showGpuVerify);
  $('deploy').addEventListener('click', deploySelected);
  updatePreview();

  if (deployNow) deploySelected();
}

function gpuModeLabel(mode) {
  return {
    off: 'Off (no passthrough)',
    drm: 'DRM — /dev/dri (Intel/AMD graphics)',
    rocm: 'ROCm — AMD compute (/dev/dri + /dev/kfd)',
    nvidia: 'NVIDIA — --gpus all',
  }[mode] || mode;
}

function encoderLabel(enc) {
  return {
    nvenc: 'NVENC (NVIDIA hardware)',
    qsv: 'Quick Sync (Intel hardware)',
    vaapi: 'VA-API (Intel/AMD hardware)',
    software: 'Software (libx264, CPU)',
  }[enc] || enc;
}

const lines = (v) => String(v || '').split('\n').map((s) => s.trim()).filter(Boolean);

function currentRequest() {
  return {
    tag: SELECTED.id,
    hostPort: Number($('host-port').value) || 0,
    dashboardPort: Number($('dash-port').value) || 0,
    name: $('name').value || null,
    shmSize: $('shm').value || null,
    gpuMode: $('gpu-mode').value || 'off',
    encoder: $('encoder').value || null,
    memory: $('memory').value || null,
    cpus: $('cpus').value || null,
    env: lines($('env').value),
    volumes: lines($('volumes').value),
  };
}

let previewTimer = null;
let FORMAT = 'run';

function setFormat(fmt) {
  FORMAT = fmt;
  const run = $('fmt-run');
  const comp = $('fmt-compose');
  if (run) { run.classList.toggle('active', fmt === 'run'); run.setAttribute('aria-selected', String(fmt === 'run')); }
  if (comp) { comp.classList.toggle('active', fmt === 'compose'); comp.setAttribute('aria-selected', String(fmt === 'compose')); }
  doPreview();
}

function updatePreview() {
  clearTimeout(previewTimer);
  previewTimer = setTimeout(doPreview, 120);
}

async function doPreview() {
  if (!SELECTED) return;
  const seq = ++PREVIEW_SEQ;
  const cmd = FORMAT === 'compose' ? 'preview_compose' : 'preview_run_args';
  try {
    const text = await invoke(cmd, { req: currentRequest() });
    if (seq !== PREVIEW_SEQ) return; // a newer request superseded this one
    LAST_CMD = text;
    const el = $('preview');
    if (el) el.textContent = text;
  } catch (err) {
    const el = $('preview');
    if (el) el.textContent = `(preview unavailable: ${err})`;
  }
}

async function deploySelected() {
  if (!SELECTED) return;
  const btn = $('deploy');
  const out = $('deploy-result');
  btn.disabled = true;
  out.className = 'result';
  out.textContent = 'Deploying… (the first pull can take a while)';
  try {
    const res = await invoke('deploy', { req: currentRequest() });
    if (res.ok) {
      out.className = 'result ok';
      out.textContent = `Running. Desktop at http://localhost:${res.host_port}`;
      toast(`Deployed ${SELECTED.name}`);
      openUrl(`http://localhost:${res.host_port}`);
      refreshInstances();
    } else {
      out.className = 'result err';
      out.textContent = `Failed: ${res.error || 'unknown error'}`;
      toast('Deploy failed', true);
    }
  } catch (err) {
    out.className = 'result err';
    out.textContent = `Failed: ${err}`;
    toast('Deploy failed', true);
  } finally {
    btn.disabled = false;
  }
}

// ---------------------------------------------------------------- instances

async function refreshInstances() {
  const list = $('instances');
  let rows = [];
  try {
    rows = await invoke('list_instances');
  } catch (err) {
    list.innerHTML = `<div class="empty">Could not list containers: ${escapeHtml(err)}</div>`;
    return;
  }
  LAST_INSTANCES = rows;
  $('instance-count').textContent = rows.length ? `· ${rows.length}` : '';
  if (rows.length === 0) {
    list.innerHTML = '<div class="empty">No instances yet. Deploy one from the store above.</div>';
    STATS = {};
    return;
  }
  list.innerHTML = '';
  for (const c of rows) {
    const up = /^up/i.test(c.status);
    const stat = STATS[c.id];
    const row = document.createElement('div');
    row.className = 'row';
    row.innerHTML = `
      <div>
        <div class="name">${escapeHtml(c.name)} <span class="pill ${up ? 'up' : ''}">${escapeHtml(c.state)}</span></div>
        <div class="meta">${escapeHtml(c.image)} · ${escapeHtml(c.status)}${stat ? ` · <span class="stat">${escapeHtml(stat.cpu)} CPU · ${escapeHtml(stat.mem)}</span>` : ''}</div>
      </div>
      <div class="actions"></div>`;
    const actions = row.querySelector('.actions');
    if (c.desktop_port) actions.appendChild(ghost('Open', () => openUrl(`http://localhost:${c.desktop_port}`)));
    if (c.dashboard_port) actions.appendChild(ghost('Dashboard', () => openUrl(`http://localhost:${c.dashboard_port}`)));
    actions.appendChild(ghost('Logs', () => showLogs(c)));
    if (up) actions.appendChild(ghost('Stop', async () => { await invoke('stop_instance', { id: c.id }); refreshInstances(); }));
    actions.appendChild(ghost('Remove', async () => { await invoke('remove_instance', { id: c.id }); refreshInstances(); }));
    list.appendChild(row);
  }
}

async function refreshStats() {
  const running = LAST_INSTANCES.filter((c) => /^up/i.test(c.status));
  if (running.length === 0) { STATS = {}; return; }
  try {
    const stats = await invoke('container_stats', { ids: running.map((c) => c.id) });
    STATS = {};
    for (const s of stats) STATS[s.id] = s;
  } catch { /* stats are best-effort */ }
}

function ghost(label, onClick) {
  const b = document.createElement('button');
  b.className = 'ghost';
  b.textContent = label;
  b.addEventListener('click', onClick);
  return b;
}

// --------------------------------------------------------------- logs modal

async function loadLogs(container) {
  try {
    const text = await invoke('instance_logs', { id: container.id });
    const body = $('modal-body');
    const atBottom = body.scrollTop + body.clientHeight >= body.scrollHeight - 20;
    body.textContent = text || '(no output)';
    if (atBottom) body.scrollTop = body.scrollHeight;
  } catch (err) {
    toast(`Logs failed: ${err}`, true);
  }
}

function showLogs(container) {
  $('modal-title').textContent = `Logs · ${container.name}`;
  $('modal-body').textContent = 'Loading…';
  $('modal').classList.remove('hidden');
  loadLogs(container);
  clearInterval(LOGS_TIMER);
  LOGS_TIMER = setInterval(() => loadLogs(container), LOGS_REFRESH_MS);
}

function closeModal() {
  $('modal').classList.add('hidden');
  clearInterval(LOGS_TIMER);
  LOGS_TIMER = null;
}

/// Open the shared modal with arbitrary (already-escaped) HTML. Stops any log
/// tailing so the two never fight over the body.
function openModal(title, html) {
  clearInterval(LOGS_TIMER);
  LOGS_TIMER = null;
  $('modal-title').textContent = title;
  $('modal-body').innerHTML = html;
  $('modal').classList.remove('hidden');
}

// --------------------------------------------------------------------- init

function startInstancePolling() {
  clearInterval(INSTANCES_TIMER);
  INSTANCES_TIMER = setInterval(async () => {
    // Don't churn while the user is reading logs or the window is hidden.
    if (!$('modal').classList.contains('hidden') || document.hidden) return;
    await refreshInstances();
    await refreshStats();
    // Re-render so the fresh stats show up.
    renderInstanceStats();
  }, INSTANCES_REFRESH_MS);
}

function renderInstanceStats() {
  const rows = [...$('instances').querySelectorAll('.row')];
  LAST_INSTANCES.forEach((c, i) => {
    const stat = STATS[c.id];
    const meta = rows[i] && rows[i].querySelector('.meta');
    if (meta && stat && !meta.querySelector('.stat')) {
      meta.insertAdjacentHTML('beforeend', ` · <span class="stat">${escapeHtml(stat.cpu)} CPU · ${escapeHtml(stat.mem)}</span>`);
    }
  });
}

function bindShortcuts() {
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      $('search').focus();
      $('search').select();
    } else if (e.key === 'Escape' && !$('modal').classList.contains('hidden')) {
      closeModal();
    } else if (e.key === '/' && e.target === document.body) {
      e.preventDefault();
      $('search').focus();
    }
  });
}

async function init() {
  loadFavorites();
  $('search').addEventListener('input', renderGrid);
  $('sort').addEventListener('change', (e) => { SORT = e.target.value; renderGrid(); });
  $('refresh').addEventListener('click', async () => { await refreshInstances(); await refreshStats(); renderInstanceStats(); });
  $('stop-all').addEventListener('click', async () => {
    const n = await invoke('stop_all_instances');
    toast(`Stopped ${n} instance${n === 1 ? '' : 's'}`);
    await refreshInstances();
  });
  $('modal-close').addEventListener('click', closeModal);
  $('gpu-status').addEventListener('click', showGpuDetails);
  bindShortcuts();

  try {
    const mp = await invoke('marketplace');
    APPS = mp.apps;
    DOCKER_OK = mp.docker_available;
    HOST_GPU = mp.gpu || HOST_GPU;

    const status = $('docker-status');
    if (mp.docker_available) {
      status.textContent = `Docker ${mp.docker_version}`;
      status.className = 'status ok';
    } else {
      status.textContent = 'Docker not found';
      status.className = 'status err';
    }
    renderGpuStatus();
    renderTabs();
    renderGrid();
  } catch (err) {
    toast(`Could not load marketplace: ${err}`, true);
  }
  await refreshInstances();
  await refreshStats();
  renderInstanceStats();
  startInstancePolling();
}

window.addEventListener('DOMContentLoaded', init);
