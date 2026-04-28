// FastVM Management Dashboard
// ----------------------------------------------------------------------------
// HTTP + WebSocket server on port 3001. Streams real-time CPU/memory/disk
// metrics to the browser, exposes REST endpoints for snapshots, recordings,
// clipboard, and scheduled tasks.
//
// Authentication: a single token stored in $FASTVM_DASHBOARD_TOKEN_FILE
// (default /config/dashboard.token). Generated on first launch. Pass it as
// `?token=...` or `Authorization: Bearer ...`.

'use strict';

const express = require('express');
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { WebSocketServer } = require('ws');

const snapshots = require('./api/snapshots');
const performance = require('./api/performance');
const tasks = require('./api/tasks');
const recording = require('./api/recording');
const clipboard = require('./api/clipboard');

const PORT = parseInt(process.env.FASTVM_DASHBOARD_PORT || '3001', 10);
const DATA_ROOT = process.env.FASTVM_DATA_ROOT || '/config';
const TOKEN_FILE = process.env.FASTVM_DASHBOARD_TOKEN_FILE
    || path.join(DATA_ROOT, 'dashboard.token');

// ---------------------------------------------------------------- token mgmt
function ensureToken() {
    try {
        return fs.readFileSync(TOKEN_FILE, 'utf8').trim();
    } catch {
        const tok = crypto.randomBytes(24).toString('hex');
        fs.mkdirSync(path.dirname(TOKEN_FILE), { recursive: true });
        fs.writeFileSync(TOKEN_FILE, tok + '\n', { mode: 0o600 });
        console.log(`[dashboard] generated new auth token at ${TOKEN_FILE}`);
        return tok;
    }
}
const AUTH_TOKEN = ensureToken();

function checkToken(req) {
    const fromHeader = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
    const fromQuery = req.query && req.query.token;
    return fromHeader === AUTH_TOKEN || fromQuery === AUTH_TOKEN;
}

// ---------------------------------------------------------------- app setup
const app = express();
app.use(express.json({ limit: '12mb' }));
app.use(express.static(path.join(__dirname), { index: 'index.html' }));

// Public: minimal status (used by the login page).
app.get('/api/health', (_req, res) => {
    res.json({ ok: true, version: '1.0.0', uptime: process.uptime() });
});

app.post('/api/login', (req, res) => {
    const t = (req.body && req.body.token) || '';
    if (t === AUTH_TOKEN) return res.json({ ok: true });
    return res.status(401).json({ ok: false, error: 'Invalid token' });
});

// Authenticated routes.
app.use('/api', (req, res, next) => {
    if (req.path === '/health' || req.path === '/login') return next();
    if (!checkToken(req)) return res.status(401).json({ error: 'unauthorized' });
    next();
});

app.use('/api/snapshots', snapshots.router);
app.use('/api/performance', performance.router);
app.use('/api/tasks', tasks.router);
app.use('/api/recording', recording.router);
app.use('/api/clipboard', clipboard.router);

app.get('/api/whoami', (_req, res) => res.json({ ok: true, dataRoot: DATA_ROOT }));

// ---------------------------------------------------------------- server
const server = http.createServer(app);

const wss = new WebSocketServer({ noServer: true });
server.on('upgrade', (req, socket, head) => {
    const url = new URL(req.url, 'http://localhost');
    if (url.searchParams.get('token') !== AUTH_TOKEN) {
        socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
        socket.destroy();
        return;
    }
    wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
});

const broadcasters = [
    performance.startBroadcaster(wss, 5000),
];

wss.on('connection', (ws) => {
    ws.send(JSON.stringify({ type: 'hello', ts: Date.now() }));
});

// ---------------------------------------------------------------- shutdown
function shutdown() {
    console.log('[dashboard] shutting down');
    broadcasters.forEach((stop) => { try { stop(); } catch {} });
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 5000).unref();
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

server.listen(PORT, () => {
    console.log(`[dashboard] listening on :${PORT}`);
    console.log(`[dashboard] token: ${AUTH_TOKEN}`);
});
