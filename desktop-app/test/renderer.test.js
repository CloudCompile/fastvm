'use strict';

/**
 * Frontend tests for the marketplace renderer.
 *
 * Loads the real `src/index.html` + `src/renderer.js` into jsdom with a stubbed
 * `window.__TAURI__` bridge, then drives the UI the way a user would: search,
 * switch category, select an app, toggle GPU, open logs. Assertions are on the
 * resulting DOM, so they exercise the actual rendering code.
 */

const { test, afterEach } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');

const SRC = path.join(__dirname, '..', 'src');

// Every window we create, so we can tear them down (their timers would
// otherwise keep the test process alive).
const OPEN = [];
afterEach(() => {
  while (OPEN.length) {
    const dom = OPEN.pop();
    try { dom.window.close(); } catch { /* already closed */ }
  }
});

// A small but representative catalog: a featured GPU app, a couple of plain
// desktops, a flavor, and a single-app image.
const APPS = [
  { id: 'xfce4-minimal-latest', name: 'XFCE4 Minimal', tagline: 'Fast and light', category: 'Desktops', kind: 'desktop', ram: '512 MB', gpu: false, featured: true, image: 'ghcr.io/cloudcompile/fastvm:xfce4-minimal-latest' },
  { id: 'kde-gaming-latest', name: 'Gaming Rig', tagline: 'Steam and Wine', category: 'Gaming', kind: 'preset', ram: '4 GB', gpu: true, featured: true, image: 'ghcr.io/cloudcompile/fastvm:kde-gaming-latest' },
  { id: 'gnome-none-latest', name: 'GNOME', tagline: 'The sleek desktop', category: 'Desktops', kind: 'desktop', ram: '2 GB', gpu: false, featured: false, image: 'ghcr.io/cloudcompile/fastvm:gnome-none-latest' },
  { id: 'pearos-latest', name: 'pearOS', tagline: 'macOS-inspired', category: 'Distros', kind: 'flavor', ram: '1.5 GB', gpu: false, featured: true, image: 'ghcr.io/cloudcompile/fastvm:pearos-latest' },
  { id: 'terminal-latest', name: 'Terminal only', tagline: 'A bare terminal', category: 'Minimal', kind: 'single', ram: '128 MB', gpu: false, featured: false, image: 'ghcr.io/cloudcompile/fastvm:terminal-latest' },
];

/** Build a jsdom window with the app loaded and the Tauri bridge stubbed. */
async function boot({ gpu = { present: true, vendor: 'amd', render_node: '/dev/dri/renderD128', devices: [] }, docker = { available: true, version: '27.3.1' } } = {}) {
  const html = fs.readFileSync(path.join(SRC, 'index.html'), 'utf8');
  const renderer = fs.readFileSync(path.join(SRC, 'renderer.js'), 'utf8');
  const calls = [];
  const opened = [];

  const dom = new JSDOM(html.replace('<script src="renderer.js"></script>', ''), {
    runScripts: 'outside-only',
    url: 'http://localhost/',
  });
  OPEN.push(dom);
  const { window } = dom;

  window.__TAURI__ = {
    core: {
      invoke: async (cmd, args) => {
        calls.push({ cmd, args });
        switch (cmd) {
          case 'marketplace':
            return { apps: APPS, variant_count: 236, docker_available: docker.available, docker_version: docker.available ? docker.version : null, gpu };
          case 'preview_run_args':
            // Mirror the backend format closely enough to assert on it.
            return `docker run -d -p ${args.req.hostPort || 3000}:3000 ${args.req.gpu ? '--device /dev/dri ' : ''}ghcr.io/cloudcompile/fastvm:${args.req.tag}`;
          case 'list_instances':
            return [{ id: 'abc', name: 'FastVM-pearOS', image: 'ghcr.io/cloudcompile/fastvm:pearos-latest', state: 'running', status: 'Up 2 minutes', desktop_port: 3000, dashboard_port: 3001 }];
          case 'instance_logs':
            return '[fastvm] ready';
          default:
            return null;
        }
      },
    },
    opener: { openUrl: (u) => opened.push(u) },
  };

  window.eval(renderer);
  window.document.dispatchEvent(new window.Event('DOMContentLoaded'));
  // Let the awaited invoke() promises settle.
  await new Promise((r) => setTimeout(r, 0));
  await new Promise((r) => setTimeout(r, 0));

  return { window, doc: window.document, calls, opened };
}

const $$ = (doc, sel) => [...doc.querySelectorAll(sel)];
const tick = () => new Promise((r) => setTimeout(r, 0));

test('renders the catalog and docker/GPU status', async () => {
  const { doc } = await boot();
  assert.equal($$(doc, '.card').length, APPS.length);
  assert.match(doc.getElementById('docker-status').textContent, /Docker 27\.3\.1/);
  assert.match(doc.getElementById('gpu-status').textContent, /GPU: amd/);
  assert.match(doc.getElementById('result-count').textContent, /5 of 5 images/);
});

test('reports missing docker and missing GPU', async () => {
  const { doc } = await boot({ docker: { available: false }, gpu: { present: false, vendor: 'none', render_node: null, devices: [] } });
  assert.equal(doc.getElementById('docker-status').textContent, 'Docker not found');
  assert.equal(doc.getElementById('gpu-status').textContent, 'No GPU');
});

test('search filters the grid', async () => {
  const { window, doc } = await boot();
  const search = doc.getElementById('search');
  search.value = 'gaming';
  search.dispatchEvent(new window.Event('input'));
  const titles = $$(doc, '.card .title').map((e) => e.textContent);
  assert.deepEqual(titles, ['Gaming Rig']);
});

test('category tabs filter the grid', async () => {
  const { window, doc } = await boot();
  const tab = $$(doc, '.tab').find((t) => t.textContent === 'Distros');
  tab.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  const titles = $$(doc, '.card .title').map((e) => e.textContent);
  assert.deepEqual(titles, ['pearOS']);
});

test('selecting an app renders details and a backend command preview', async () => {
  const { window, doc, calls } = await boot();
  // Click the card (not the Deploy button).
  const card = $$(doc, '.card').find((c) => c.querySelector('.title').textContent === 'pearOS');
  card.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

  assert.ok(doc.getElementById('deploy'), 'deploy button rendered');
  assert.match(doc.getElementById('deploy').textContent, /Deploy pearOS/);
  // The preview comes from the backend command.
  await new Promise((r) => setTimeout(r, 200));
  assert.ok(calls.some((c) => c.cmd === 'preview_run_args'), 'preview_run_args invoked');
  assert.match(doc.getElementById('preview').textContent, /docker run -d -p 3000:3000/);
});

test('GPU checkbox is enabled only when a GPU is present', async () => {
  const withGpu = await boot();
  const cardA = $$(withGpu.doc, '.card').find((c) => c.querySelector('.title').textContent === 'Gaming Rig');
  cardA.dispatchEvent(new withGpu.window.MouseEvent('click', { bubbles: true }));
  const gpuBox = withGpu.doc.getElementById('gpu');
  assert.equal(gpuBox.disabled, false);
  assert.equal(gpuBox.checked, true, 'gaming app defaults to GPU on when host has a GPU');

  const noGpu = await boot({ gpu: { present: false, vendor: 'none', render_node: null, devices: [] } });
  const cardB = $$(noGpu.doc, '.card').find((c) => c.querySelector('.title').textContent === 'Gaming Rig');
  cardB.dispatchEvent(new noGpu.window.MouseEvent('click', { bubbles: true }));
  const boxB = noGpu.doc.getElementById('gpu');
  assert.equal(boxB.disabled, true, 'checkbox disabled without a GPU');
  assert.equal(boxB.checked, false);
});

test('toggling GPU re-requests the preview with the device flag', async () => {
  const { window, doc, calls } = await boot();
  const card = $$(doc, '.card').find((c) => c.querySelector('.title').textContent === 'Gaming Rig');
  card.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await new Promise((r) => setTimeout(r, 200));

  const box = doc.getElementById('gpu');
  box.checked = false;
  box.dispatchEvent(new window.Event('change'));
  await new Promise((r) => setTimeout(r, 200));

  const last = calls.filter((c) => c.cmd === 'preview_run_args').pop();
  assert.equal(last.args.req.gpu, false);
});

test('logs modal opens and fetches logs', async () => {
  const { window, doc, calls } = await boot();
  const logsBtn = $$(doc, '.row .ghost').find((b) => b.textContent === 'Logs');
  logsBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await tick();
  assert.equal(doc.getElementById('modal').classList.contains('hidden'), false);
  assert.match(doc.getElementById('modal-title').textContent, /FastVM-pearOS/);
  assert.match(doc.getElementById('modal-body').textContent, /ready/);
  assert.ok(calls.some((c) => c.cmd === 'instance_logs'));
});

test('escape closes the logs modal', async () => {
  const { window, doc } = await boot();
  const logsBtn = $$(doc, '.row .ghost').find((b) => b.textContent === 'Logs');
  logsBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await tick();
  doc.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
  assert.equal(doc.getElementById('modal').classList.contains('hidden'), true);
});

test('Ctrl+K focuses search', async () => {
  const { window, doc } = await boot();
  doc.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'k', ctrlKey: true, bubbles: true }));
  assert.equal(doc.activeElement, doc.getElementById('search'));
});
