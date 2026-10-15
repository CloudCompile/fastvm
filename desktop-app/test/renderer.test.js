'use strict';

/**
 * Frontend tests for the marketplace renderer.
 *
 * Loads the real `src/index.html` + `src/renderer.js` into jsdom with a stubbed
 * `window.__TAURI__` bridge, then drives the UI the way a user would: search,
 * sort, star, switch category, select an app, pick a GPU mode, open logs.
 * Assertions are on the resulting DOM, so they exercise the actual rendering.
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

const APPS = [
  { id: 'xfce4-minimal-latest', name: 'XFCE4 Minimal', tagline: 'Fast and light', category: 'Desktops', kind: 'desktop', ram: '512 MB', gpu: false, featured: true, image: 'ghcr.io/cloudcompile/fastvm:xfce4-minimal-latest' },
  { id: 'kde-gaming-latest', name: 'Gaming Rig', tagline: 'Steam and Wine', category: 'Gaming', kind: 'preset', ram: '4 GB', gpu: true, featured: true, image: 'ghcr.io/cloudcompile/fastvm:kde-gaming-latest' },
  { id: 'gnome-none-latest', name: 'GNOME', tagline: 'The sleek desktop', category: 'Desktops', kind: 'desktop', ram: '2 GB', gpu: false, featured: false, image: 'ghcr.io/cloudcompile/fastvm:gnome-none-latest' },
  { id: 'pearos-latest', name: 'pearOS', tagline: 'macOS-inspired', category: 'Distros', kind: 'flavor', ram: '1.5 GB', gpu: false, featured: true, image: 'ghcr.io/cloudcompile/fastvm:pearos-latest' },
  { id: 'terminal-latest', name: 'Terminal only', tagline: 'A bare terminal', category: 'Minimal', kind: 'single', ram: '128 MB', gpu: false, featured: false, image: 'ghcr.io/cloudcompile/fastvm:terminal-latest' },
];

const AMD_GPU = {
  present: true, vendor: 'amd', render_node: '/dev/dri/renderD128', devices: [],
  kfd: true, toolkit: false, modes: ['rocm', 'drm', 'off'], recommended: 'rocm',
};
const NVIDIA_GPU = {
  present: true, vendor: 'nvidia', render_node: '/dev/dri/renderD128', devices: [],
  kfd: false, toolkit: false, modes: ['nvidia', 'drm', 'off'], recommended: 'nvidia',
  warning: 'NVIDIA container toolkit not detected — install it and run `nvidia-ctk runtime configure --runtime=docker` before using --gpus',
};
const NO_GPU = {
  present: false, vendor: 'none', render_node: null, devices: [],
  kfd: false, toolkit: false, modes: ['off'], recommended: 'off',
};

/** Build a jsdom window with the app loaded and the Tauri bridge stubbed. */
async function boot({
  gpu = AMD_GPU,
  docker = { available: true, version: '27.3.1' },
  instances = [{ id: 'abc', name: 'FastVM-pearOS', image: 'ghcr.io/cloudcompile/fastvm:pearos-latest', state: 'running', status: 'Up 2 minutes', desktop_port: 3000, dashboard_port: 3001 }],
  stats = [{ id: 'abc', cpu: '1.24%', mem: '256MiB / 8GiB' }],
} = {}) {
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
          case 'preview_run_args': {
            const r = args.req;
            const out = ['docker', 'run', '-d'];
            if (r.name) out.push('--name', r.name);
            out.push('-p', `${r.hostPort || 3000}:3000`);
            if (r.dashboardPort) out.push('-p', `${r.dashboardPort}:8099`);
            if (r.shmSize) out.push('--shm-size', r.shmSize);
            if (r.memory) out.push('--memory', r.memory);
            if (r.cpus) out.push('--cpus', r.cpus);
            const mode = r.gpuMode || 'off';
            if (mode === 'nvidia') out.push('--gpus', 'all');
            else if (mode === 'rocm') out.push('--device', '/dev/dri', '--device', '/dev/kfd', '--group-add', 'keep-groups');
            else if (mode === 'drm') out.push('--device', '/dev/dri');
            // Mirror the backend's mode-implied env.
            const modeEnv = {
              drm: ['FASTVM_GPU_HW=true', 'FASTVM_RECORDING_ENCODER=vaapi'],
              rocm: ['DISABLE_DRI=1', 'FASTVM_GPU_HW=false', 'FASTVM_RECORDING_ENCODER=software'],
              nvidia: ['NVIDIA_DRIVER_CAPABILITIES=compute,video,utility', 'FASTVM_RECORDING_ENCODER=nvenc'],
            }[mode] || [];
            for (const e of modeEnv) out.push('-e', e);
            for (const e of r.env || []) out.push('-e', e);
            for (const v of r.volumes || []) out.push('-v', v);
            out.push(`ghcr.io/cloudcompile/fastvm:${r.tag}`);
            return out.join(' ');
          }
          case 'list_instances':
            return instances;
          case 'preview_compose':
            return `services:\n  fastvm:\n    image: ghcr.io/cloudcompile/fastvm:${args.req.tag}\n    ports:\n      - "${args.req.hostPort || 3000}:3000"`;
          case 'container_stats':
            return stats;
          case 'gpu_verify':
            return ['nvidia-smi                                 # expect: driver + GPU table', 'ffmpeg -hide_banner -encoders | grep nvenc # expect: h264_nvenc'];
          case 'instance_logs':
            return '[fastvm] ready';
          case 'stop_all_instances':
            return 1;
          default:
            return null;
        }
      },
    },
    opener: { openUrl: (u) => opened.push(u) },
  };

  window.eval(renderer);
  window.document.dispatchEvent(new window.Event('DOMContentLoaded'));
  await new Promise((r) => setTimeout(r, 0));
  await new Promise((r) => setTimeout(r, 0));

  return { window, doc: window.document, calls, opened };
}

const $$ = (doc, sel) => [...doc.querySelectorAll(sel)];
const tick = () => new Promise((r) => setTimeout(r, 0));
const titles = (doc) => $$(doc, '.card .title').map((e) => e.textContent);
const clickCard = (window, doc, name) => {
  const card = $$(doc, '.card').find((c) => c.querySelector('.title').textContent === name);
  card.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
};

test('renders the catalog and docker/GPU status', async () => {
  const { doc } = await boot();
  assert.equal($$(doc, '.card').length, APPS.length);
  assert.match(doc.getElementById('docker-status').textContent, /Docker 27\.3\.1/);
  assert.match(doc.getElementById('gpu-status').textContent, /GPU: amd/);
  assert.match(doc.getElementById('result-count').textContent, /5 of 5 images/);
});

test('reports missing docker and missing GPU', async () => {
  const { doc } = await boot({ docker: { available: false }, gpu: NO_GPU });
  assert.equal(doc.getElementById('docker-status').textContent, 'Docker not found');
  assert.equal(doc.getElementById('gpu-status').textContent, 'No GPU');
});

test('search filters the grid', async () => {
  const { window, doc } = await boot();
  const search = doc.getElementById('search');
  search.value = 'gaming';
  search.dispatchEvent(new window.Event('input'));
  assert.deepEqual(titles(doc), ['Gaming Rig']);
});

test('category tabs filter the grid', async () => {
  const { window, doc } = await boot();
  const tab = $$(doc, '.tab').find((t) => t.textContent === 'Distros');
  tab.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.deepEqual(titles(doc), ['pearOS']);
});

test('sorting by name reorders the grid', async () => {
  const { window, doc } = await boot();
  const sort = doc.getElementById('sort');
  sort.value = 'name';
  sort.dispatchEvent(new window.Event('change'));
  const t = titles(doc);
  assert.deepEqual(t, [...t].sort((a, b) => a.localeCompare(b)));
});

test('starring a favorite persists and reorders featured', async () => {
  const { window, doc } = await boot();
  const star = $$(doc, '.card').find((c) => c.querySelector('.title').textContent === 'Terminal only').querySelector('.star');
  star.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.equal(window.localStorage.getItem('fastvm.favorites'), JSON.stringify(['terminal-latest']));
  // A starred app now appears under the Featured tab.
  const tab = $$(doc, '.tab').find((t) => t.textContent === 'Featured');
  tab.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.ok(titles(doc).includes('Terminal only'));
});

test('selecting an app renders details and a backend command preview', async () => {
  const { window, doc, calls } = await boot();
  clickCard(window, doc, 'pearOS');
  assert.match(doc.getElementById('deploy').textContent, /Deploy pearOS/);
  await new Promise((r) => setTimeout(r, 200));
  assert.ok(calls.some((c) => c.cmd === 'preview_run_args'), 'preview_run_args invoked');
  assert.match(doc.getElementById('preview').textContent, /docker run -d -p 3000:3000/);
});

test('GPU mode selector is disabled without a GPU and offers modes with one', async () => {
  const amd = await boot();
  clickCard(amd.window, amd.doc, 'Gaming Rig');
  const sel = amd.doc.getElementById('gpu-mode');
  assert.equal(sel.disabled, false);
  assert.deepEqual([...sel.options].map((o) => o.value), ['off', 'rocm', 'drm']);
  assert.equal(sel.value, 'rocm', 'AMD host with kfd recommends rocm');

  const none = await boot({ gpu: NO_GPU });
  clickCard(none.window, none.doc, 'Gaming Rig');
  assert.equal(none.doc.getElementById('gpu-mode').disabled, true);
});

test('a host warning is surfaced in the details panel', async () => {
  const { window, doc } = await boot({ gpu: NVIDIA_GPU });
  clickCard(window, doc, 'Gaming Rig');
  const warn = doc.querySelector('.warn');
  assert.ok(warn, 'warning element present');
  assert.match(warn.textContent, /NVIDIA container toolkit not detected/);
});

test('choosing an NVIDIA mode previews --gpus all', async () => {
  const { window, doc, calls } = await boot({ gpu: NVIDIA_GPU });
  clickCard(window, doc, 'Gaming Rig');
  await new Promise((r) => setTimeout(r, 200));
  assert.match(doc.getElementById('preview').textContent, /--gpus all/);
  const last = calls.filter((c) => c.cmd === 'preview_run_args').pop();
  assert.equal(last.args.req.gpuMode, 'nvidia');
});

test('advanced options flow into the preview', async () => {
  const { window, doc } = await boot();
  clickCard(window, doc, 'pearOS');
  await new Promise((r) => setTimeout(r, 200));
  doc.getElementById('memory').value = '4g';
  doc.getElementById('memory').dispatchEvent(new window.Event('input'));
  doc.getElementById('env').value = 'TZ=Etc/UTC';
  doc.getElementById('env').dispatchEvent(new window.Event('input'));
  doc.getElementById('volumes').value = '/tmp/work:/work';
  doc.getElementById('volumes').dispatchEvent(new window.Event('input'));
  await new Promise((r) => setTimeout(r, 220));
  const cmd = doc.getElementById('preview').textContent;
  assert.match(cmd, /--memory 4g/);
  assert.match(cmd, /-e TZ=Etc\/UTC/);
  assert.match(cmd, /-v \/tmp\/work:\/work/);
});

test('the verify button opens a modal with backend steps', async () => {
  const { window, doc, calls } = await boot({ gpu: NVIDIA_GPU });
  clickCard(window, doc, 'Gaming Rig');
  await new Promise((r) => setTimeout(r, 150));
  doc.getElementById('gpu-verify').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await new Promise((r) => setTimeout(r, 150));
  const last = calls.filter((c) => c.cmd === 'gpu_verify').pop();
  assert.equal(last.args.mode, 'nvidia');
  assert.match(doc.getElementById('modal-title').textContent, /Verify GPU/);
  assert.match(doc.getElementById('modal-body').textContent, /nvidia-smi/);
});

test('switching to compose preview calls preview_compose', async () => {
  const { window, doc, calls } = await boot();
  clickCard(window, doc, 'pearOS');
  await new Promise((r) => setTimeout(r, 200));
  doc.getElementById('fmt-compose').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await new Promise((r) => setTimeout(r, 200));
  assert.ok(calls.some((c) => c.cmd === 'preview_compose'), 'preview_compose invoked');
  assert.match(doc.getElementById('preview').textContent, /services:/);
  assert.match(doc.getElementById('preview').textContent, /image: ghcr\.io\/cloudcompile\/fastvm:pearos-latest/);
  // And back to the docker run form.
  doc.getElementById('fmt-run').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await new Promise((r) => setTimeout(r, 200));
  assert.match(doc.getElementById('preview').textContent, /docker run -d/);
});

test('instances show live stats', async () => {
  const { doc } = await boot();
  await tick();
  const meta = doc.querySelector('.row .meta');
  assert.match(meta.textContent, /1\.24% CPU/);
  assert.match(meta.textContent, /256MiB \/ 8GiB/);
});

test('stop all stops running instances', async () => {
  const { window, doc, calls } = await boot();
  doc.getElementById('stop-all').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  await tick();
  assert.ok(calls.some((c) => c.cmd === 'stop_all_instances'));
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

test('clicking the GPU status shows host details', async () => {
  const { window, doc } = await boot();
  doc.getElementById('gpu-status').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  const toast = doc.getElementById('toast');
  assert.match(toast.textContent, /ROCm compute/);
});
