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

test.after(() => server.close());
