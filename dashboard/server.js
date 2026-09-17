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
const analytics = require('./api/analytics');

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
const VERSION = process.env.FASTVM_VERSION || 'dev';
const COMMIT = process.env.FASTVM_COMMIT || 'unknown';
const allowQueryToken = process.env.FASTVM_ALLOW_QUERY_TOKEN === 'true';
const loginAttempts = new Map();

function constantTimeEqual(a, b) {
    const left = Buffer.from(String(a || ''));
    const right = Buffer.from(String(b || ''));
    return left.length === right.length && crypto.timingSafeEqual(left, right);
}

function checkToken(req) {
    const fromHeader = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
    const fromQuery = req.query && req.query.token;
    return constantTimeEqual(fromHeader, AUTH_TOKEN)
        || (allowQueryToken && constantTimeEqual(fromQuery, AUTH_TOKEN));
}

function errorResponse(res, status, message, code) {
    return res.status(status).json({ ok: false, error: message, code });
}

// ---------------------------------------------------------------- app setup
const app = express();
app.use(express.json({ limit: '12mb' }));
app.use(express.static(path.join(__dirname), { index: 'index.html' }));

// Public: minimal status (used by the login page).
app.get('/api/health', (_req, res) => {
    res.json({ ok: true, version: VERSION, commit: COMMIT, uptime: process.uptime() });
});

app.post('/api/login', (req, res) => {
    const t = (req.body && req.body.token) || '';
    const address = req.ip || 'unknown';
    const now = Date.now();
    const attempts = (loginAttempts.get(address) || []).filter((time) => now - time < 60000);
    if (attempts.length >= 10) return errorResponse(res, 429, 'Too many login attempts', 'RATE_LIMITED');
    attempts.push(now);
    loginAttempts.set(address, attempts);
    if (constantTimeEqual(t, AUTH_TOKEN)) return res.json({ ok: true });
    return errorResponse(res, 401, 'Invalid token', 'INVALID_TOKEN');
});

// Authenticated routes.
app.use('/api', (req, res, next) => {
    if (req.path === '/health' || req.path === '/login') return next();
    if (!checkToken(req)) return errorResponse(res, 401, 'Unauthorized', 'UNAUTHORIZED');
    next();
});

// Track activity for all authenticated requests
app.use('/api', analytics.trackActivity);

app.use('/api/snapshots', snapshots.router);
app.use('/api/performance', performance.router);
app.use('/api/tasks', tasks.router);
app.use('/api/recording', recording.router);
app.use('/api/clipboard', clipboard.router);
app.use('/api/analytics', analytics.router);

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

server.on('close', () => {
    broadcasters.forEach((stop) => { try { stop(); } catch {} });
    try { wss.close(); } catch {}
});

wss.on('connection', (ws) => {
    ws.send(JSON.stringify({ type: 'hello', ts: Date.now() }));
});

// ---------------------------------------------------------------- shutdown
function shutdown() {
    console.log('[dashboard] shutting down');
    analytics.trackSessionEnd();
    broadcasters.forEach((stop) => { try { stop(); } catch {} });
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 5000).unref();
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

server.listen(PORT, () => {
    analytics.trackSessionStart();
    console.log(`[dashboard] listening on :${PORT}`);
    console.log(`[dashboard] token stored at ${TOKEN_FILE}`);
    console.log(`[dashboard] analytics tracking enabled`);
});

module.exports = server;
