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
let HOST_GPU = { present: false, vendor: 'none', render_node: null, devices: [] };
let LAST_CMD = '';
let INSTANCES_TIMER = null;
let LOGS_TIMER = null;
let PREVIEW_SEQ = 0;

const INSTANCES_REFRESH_MS = 5000;
const LOGS_REFRESH_MS = 3000;

const CATEGORY_ORDER = [
  'Featured', 'Desktops', 'Gaming', 'Development', 'Content Creation',
  'Office', 'Security', 'Distros', 'Minimal', 'All',
];

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

// ------------------------------------------------------------------ status

function renderGpuStatus() {
  const el = $('gpu-status');
  if (HOST_GPU.present) {
    const vendor = HOST_GPU.vendor && HOST_GPU.vendor !== 'none' ? HOST_GPU.vendor : 'GPU';
    el.textContent = `GPU: ${vendor}`;
    el.title = HOST_GPU.render_node
      ? `Detected ${vendor} — ${HOST_GPU.render_node}`
      : `Detected ${vendor} — /dev/dri`;
    el.className = 'status ok';
  } else {
    el.textContent = 'No GPU';
    el.title = 'No /dev/dri graphics device detected on this host';
    el.className = 'status';
  }
}

// ------------------------------------------------------------------ catalog

function renderTabs() {
  const cats = new Set(APPS.map((a) => a.category));
  const tabs = CATEGORY_ORDER.filter((c) => {
    if (c === 'All') return true;
    if (c === 'Featured') return APPS.some((a) => a.featured);
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
  return APPS.filter((a) => {
    const inFilter = FILTER === 'All'
      || (FILTER === 'Featured' ? a.featured : a.category === FILTER);
    const inSearch = !q
      || a.name.toLowerCase().includes(q)
      || a.tagline.toLowerCase().includes(q)
      || a.id.toLowerCase().includes(q)
      || a.category.toLowerCase().includes(q);
    return inFilter && inSearch;
  });
}

function renderGrid() {
  const grid = $('grid');
  const apps = visibleApps();
  grid.innerHTML = '';
  $('no-results').classList.toggle('hidden', apps.length > 0);
  $('result-count').textContent = apps.length ? `${apps.length} of ${APPS.length} images` : '';
  for (const a of apps) {
    const card = document.createElement('div');
    card.className = 'card' + (SELECTED && SELECTED.id === a.id ? ' selected' : '');
    card.setAttribute('role', 'listitem');
    card.tabIndex = 0;
    card.innerHTML = `
      <div class="head">
        <span class="title">${escapeHtml(a.name)}</span>
        ${a.featured ? '<span class="chip featured">★ Featured</span>' : ''}
      </div>
      <div class="tagline">${escapeHtml(a.tagline)}</div>
      <div class="foot">
        <span class="chip">${escapeHtml(a.category)}</span>
        <span class="chip">${escapeHtml(a.ram)} RAM</span>
        ${a.gpu ? '<span class="chip gpu">GPU</span>' : ''}
      </div>
      <button class="install" data-id="${escapeHtml(a.id)}">Deploy</button>`;
    card.addEventListener('click', (e) => {
      if (e.target.classList.contains('install')) return;
      select(a);
    });
    card.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); select(a); }
    });
    card.querySelector('.install').addEventListener('click', () => select(a, true));
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
  const gpuHint = gpuAvailable ? `Host GPU: ${escapeHtml(HOST_GPU.vendor)}` : 'No /dev/dri on this host';
  const gpuChecked = (app.gpu && gpuAvailable) ? 'checked' : '';

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
    <label class="checkbox ${gpuAvailable ? '' : 'disabled'}">
      <input id="gpu" type="checkbox" ${gpuChecked} ${gpuAvailable ? '' : 'disabled'} />
      GPU passthrough (/dev/dri) <span class="hint">${gpuHint}</span>
    </label>
    <div class="preview-head">
      <span>Command</span>
      <button class="ghost tiny" id="copy-cmd">Copy</button>
    </div>
    <div class="preview" id="preview">…</div>
    <button class="primary" id="deploy">⚡ Deploy ${escapeHtml(app.name)}</button>
    <p class="result" id="deploy-result"></p>`;

  for (const id of ['host-port', 'dash-port', 'name', 'shm', 'gpu']) {
    $(id).addEventListener('input', updatePreview);
    $(id).addEventListener('change', updatePreview);
  }
  $('copy-image').addEventListener('click', () => copyText(app.image, 'Image'));
  $('copy-cmd').addEventListener('click', () => copyText(LAST_CMD, 'Command'));
  $('deploy').addEventListener('click', deploySelected);
  updatePreview();

  if (deployNow) deploySelected();
}

function currentRequest() {
  return {
    tag: SELECTED.id,
    hostPort: Number($('host-port').value) || 0,
    dashboardPort: Number($('dash-port').value) || 0,
    name: $('name').value || null,
    shmSize: $('shm').value || null,
    gpu: $('gpu').checked,
  };
}

let previewTimer = null;
function updatePreview() {
  clearTimeout(previewTimer);
  previewTimer = setTimeout(doPreview, 120);
}

async function doPreview() {
  if (!SELECTED) return;
  const seq = ++PREVIEW_SEQ;
  try {
    const cmd = await invoke('preview_run_args', { req: currentRequest() });
    if (seq !== PREVIEW_SEQ) return; // a newer request superseded this one
    LAST_CMD = cmd;
    const el = $('preview');
    if (el) el.textContent = cmd;
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
  $('instance-count').textContent = rows.length ? `· ${rows.length}` : '';
  if (rows.length === 0) {
    list.innerHTML = '<div class="empty">No instances yet. Deploy one from the store above.</div>';
    return;
  }
  list.innerHTML = '';
  for (const c of rows) {
    const up = /^up/i.test(c.status);
    const row = document.createElement('div');
    row.className = 'row';
    row.innerHTML = `
      <div>
        <div class="name">${escapeHtml(c.name)} <span class="pill ${up ? 'up' : ''}">${escapeHtml(c.state)}</span></div>
        <div class="meta">${escapeHtml(c.image)} · ${escapeHtml(c.status)}</div>
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

// --------------------------------------------------------------------- init

function startInstancePolling() {
  clearInterval(INSTANCES_TIMER);
  INSTANCES_TIMER = setInterval(() => {
    // Don't churn while the user is reading logs or the window is hidden.
    if (!$('modal').classList.contains('hidden') || document.hidden) return;
    refreshInstances();
  }, INSTANCES_REFRESH_MS);
}

function bindShortcuts() {
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      $('search').focus();
      $('search').select();
    } else if (e.key === 'Escape' && !$('modal').classList.contains('hidden')) {
      closeModal();
    }
  });
}

async function init() {
  $('search').addEventListener('input', renderGrid);
  $('refresh').addEventListener('click', refreshInstances);
  $('modal-close').addEventListener('click', closeModal);
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
  refreshInstances();
  startInstancePolling();
}

window.addEventListener('DOMContentLoaded', init);
