// Performance metrics: CPU%, memory, disk usage, network.
// Reads /proc directly so we don't need a heavyweight dependency.

'use strict';
const express = require('express');
const fs = require('fs');
const { execFileSync } = require('child_process');

const router = express.Router();
const HISTORY_LEN = 720; // ~1h at 5s cadence
const history = []; // [{ts, cpu, mem, disk, net}]

let lastCpu = null;
function readCpu() {
    const line = fs.readFileSync('/proc/stat', 'utf8').split('\n')[0];
    const parts = line.trim().split(/\s+/).slice(1).map(Number);
    const total = parts.reduce((a, b) => a + b, 0);
    const idle = parts[3] + (parts[4] || 0);
    if (!lastCpu) { lastCpu = { total, idle }; return 0; }
    const dt = total - lastCpu.total;
    const di = idle - lastCpu.idle;
    lastCpu = { total, idle };
    return dt > 0 ? Math.round(((dt - di) * 100) / dt) : 0;
}

function readMem() {
    const m = fs.readFileSync('/proc/meminfo', 'utf8');
    const get = (k) => {
        const re = new RegExp(`^${k}:\\s+(\\d+)\\s+kB`, 'm');
        const match = m.match(re);
        return match ? parseInt(match[1], 10) * 1024 : 0;
    };
    const total = get('MemTotal');
    const avail = get('MemAvailable');
    return { total, used: total - avail, pct: total ? Math.round(((total - avail) * 100) / total) : 0 };
}

function readDisk(path) {
    try {
        const out = execFileSync('df', ['-PB1', path], { encoding: 'utf8' });
        const cols = out.trim().split('\n')[1].split(/\s+/);
        const total = parseInt(cols[1], 10);
        const used = parseInt(cols[2], 10);
        return { total, used, pct: total ? Math.round((used * 100) / total) : 0 };
    } catch {
        return { total: 0, used: 0, pct: 0 };
    }
}

let lastNet = null;
function readNet() {
    let rx = 0, tx = 0;
    try {
        const lines = fs.readFileSync('/proc/net/dev', 'utf8').split('\n').slice(2);
        for (const l of lines) {
            const m = l.trim().match(/^([^:]+):\s+(\d+)(?:\s+\d+){7}\s+(\d+)/);
            if (!m) continue;
            const iface = m[1].trim();
            if (iface === 'lo') continue;
            rx += parseInt(m[2], 10);
            tx += parseInt(m[3], 10);
        }
    } catch {}
    if (!lastNet) { lastNet = { rx, tx, ts: Date.now() }; return { rx_bps: 0, tx_bps: 0 }; }
    const dt = (Date.now() - lastNet.ts) / 1000;
    const rxBps = dt > 0 ? Math.round((rx - lastNet.rx) / dt) : 0;
    const txBps = dt > 0 ? Math.round((tx - lastNet.tx) / dt) : 0;
    lastNet = { rx, tx, ts: Date.now() };
    return { rx_bps: rxBps, tx_bps: txBps };
}

function sample() {
    const sample = {
        ts: Date.now(),
        cpu: readCpu(),
        mem: readMem(),
        disk: readDisk(process.env.FASTVM_DATA_ROOT || '/config'),
        backups: readDisk(process.env.FASTVM_BACKUP_DIR || '/config/backups'),
        net: readNet(),
    };
    history.push(sample);
    if (history.length > HISTORY_LEN) history.shift();
    return sample;
}

router.get('/current', (_req, res) => res.json(history[history.length - 1] || sample()));
router.get('/history', (_req, res) => res.json(history));

function startBroadcaster(wss, intervalMs) {
    const id = setInterval(() => {
        const s = sample();
        const payload = JSON.stringify({ type: 'metrics', data: s });
        for (const client of wss.clients) {
            if (client.readyState === 1) client.send(payload);
        }
    }, intervalMs);
    return () => clearInterval(id);
}

module.exports = { router, startBroadcaster };
