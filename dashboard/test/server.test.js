const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const dataRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'fastvm-test-'));
const tokenFile = path.join(dataRoot, 'dashboard.token');
fs.writeFileSync(tokenFile, 'test-token\n', { mode: 0o600 });
process.env.FASTVM_DATA_ROOT = dataRoot;
process.env.FASTVM_DASHBOARD_TOKEN_FILE = tokenFile;
process.env.FASTVM_DASHBOARD_PORT = '0';
process.env.FASTVM_SCRIPTS_DIR = path.join(__dirname, '..');

const server = require('../server');

function request(method, url, body, token) {
    return new Promise((resolve, reject) => {
        const headers = { 'Content-Type': 'application/json' };
        if (token) headers.Authorization = `Bearer ${token}`;
        const req = http.request(`http://127.0.0.1:${server.address().port}${url}`, { method, headers }, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
        });
        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

test('health exposes version and uptime', async () => {
    const result = await request('GET', '/api/health');
    assert.equal(result.status, 200);
    assert.equal(result.body.ok, true);
    assert.equal(typeof result.body.uptime, 'number');
});

test('protected API rejects missing token', async () => {
    const result = await request('GET', '/api/whoami');
    assert.equal(result.status, 401);
    assert.equal(result.body.code, 'UNAUTHORIZED');
});

test('login accepts valid token', async () => {
    const result = await request('POST', '/api/login', { token: 'test-token' });
    assert.equal(result.status, 200);
    assert.equal(result.body.ok, true);
});

test('system update writes a durable host action request', async () => {
    const result = await request('POST', '/api/system/update', {}, 'test-token');
    assert.equal(result.status, 202);
    assert.equal(result.body.action.type, 'update');

    const status = await request('GET', '/api/system/status', undefined, 'test-token');
    assert.equal(status.status, 200);
    assert.equal(status.body.pending_action.type, 'update');
    assert.equal(JSON.parse(fs.readFileSync(path.join(dataRoot, '.fastvm', 'system-action.json'), 'utf8')).type, 'update');
});

test('gpu endpoints report detected capabilities', async () => {
    fs.mkdirSync(path.join(dataRoot, '.fastvm'), { recursive: true });
    fs.writeFileSync(
        path.join(dataRoot, '.fastvm', 'gpu.json'),
        JSON.stringify({ detected: true, vendor: 'intel', recommended_encoder: 'vaapi', encoders: { h264_vaapi: true } }),
    );

    const status = await request('GET', '/api/gpu/status', undefined, 'test-token');
    assert.equal(status.status, 200);
    assert.equal(status.body.gpu.detected, true);
    assert.equal(status.body.gpu.vendor, 'intel');

    const metrics = await request('GET', '/api/gpu/metrics', undefined, 'test-token');
    assert.equal(metrics.status, 200);
    assert.equal(metrics.body.detected, true);
    assert.equal(metrics.body.recommended_encoder, 'vaapi');
    assert.equal(metrics.body.compute_only, false);

    const system = await request('GET', '/api/system/status', undefined, 'test-token');
    assert.equal(system.status, 200);
    assert.equal(system.body.gpu.detected, true);
});

test('system status surfaces the host performance profile', async () => {
    fs.mkdirSync(path.join(dataRoot, '.fastvm'), { recursive: true });
    fs.writeFileSync(
        path.join(dataRoot, '.fastvm', 'perf-profile.json'),
        JSON.stringify({ cpus: 2, memory_mb: 8192, profile: 'constrained', compositing_off: true, raster_threads: 2, encode_threads: 1, env: { LP_NUM_THREADS: '2' } }),
    );

    const system = await request('GET', '/api/system/status', undefined, 'test-token');
    assert.equal(system.status, 200);
    assert.equal(system.body.perf.profile, 'constrained');
    assert.equal(system.body.perf.raster_threads, 2);
    assert.equal(system.body.perf.compositing_off, true);
});

test('system status surfaces the host environment report', async () => {
    fs.mkdirSync(path.join(dataRoot, '.fastvm'), { recursive: true });
    fs.writeFileSync(
        path.join(dataRoot, '.fastvm', 'environment.json'),
        JSON.stringify({
            kind: 'codespaces', cloud: 'gcp', kvm: false, shm_mb: 64, cpus: 2, memory_mb: 8192,
            notices: [{ id: 'no-kvm', severity: 'info', message: 'no kvm' }],
        }),
    );

    const system = await request('GET', '/api/system/status', undefined, 'test-token');
    assert.equal(system.status, 200);
    assert.equal(system.body.environment.kind, 'codespaces');
    assert.equal(system.body.environment.kvm, false);
    assert.equal(system.body.environment.notices[0].id, 'no-kvm');
});

test('gpu endpoints flag compute-only accelerators', async () => {
    fs.mkdirSync(path.join(dataRoot, '.fastvm'), { recursive: true });
    fs.writeFileSync(
        path.join(dataRoot, '.fastvm', 'gpu.json'),
        JSON.stringify({ detected: true, vendor: 'amd', compute_only: true, has_display: false, recommended_encoder: 'software', encoders: {} }),
    );

    const metrics = await request('GET', '/api/gpu/metrics', undefined, 'test-token');
    assert.equal(metrics.status, 200);
    assert.equal(metrics.body.vendor, 'amd');
    assert.equal(metrics.body.compute_only, true);
    assert.equal(metrics.body.recommended_encoder, 'software');
});

test('performance current reuses a recent reading', async () => {
    const first = await request('GET', '/api/performance/current', undefined, 'test-token');
    const second = await request('GET', '/api/performance/current', undefined, 'test-token');
    assert.equal(first.status, 200);
    assert.equal(second.status, 200);
    // Both requests land inside the reuse window, so they share one reading.
    assert.equal(first.body.ts, second.body.ts);
});

test('history does not grow on rapid polling', async () => {
    const before = (await request('GET', '/api/performance/history', undefined, 'test-token')).body.length;
    for (let i = 0; i < 5; i += 1) {
        await request('GET', '/api/performance/current', undefined, 'test-token');
    }
    const after = (await request('GET', '/api/performance/history', undefined, 'test-token')).body.length;
    assert.equal(after, before);
});

test.after(() => server.close());
