'use strict';
// Shared, cached system-metrics readers for the FastVM dashboard.
//
// Several API modules sample the same system counters. Re-parsing /proc and
// forking `df` for every consumer on every tick is wasteful — the dashboard
// samples on a fixed cadence and also serves ad-hoc requests. This module
// centralizes the reads and caches the ones that move slowly.

const fs = require('fs');
const { execFileSync } = require('child_process');

const MEM_TTL_MS = 1000;
const DISK_TTL_MS = 5000;

let lastCpu = null;

function readCpu() {
    let parts;
    try {
        const line = fs.readFileSync('/proc/stat', 'utf8').split('\n', 1)[0];
        parts = line.trim().split(/\s+/).slice(1).map(Number);
    } catch {
        return 0;
    }
    const total = parts.reduce((a, b) => a + b, 0);
    const idle = parts[3] + (parts[4] || 0);
    if (!lastCpu) { lastCpu = { total, idle }; return 0; }
    const dt = total - lastCpu.total;
    const di = idle - lastCpu.idle;
    lastCpu = { total, idle };
    return dt > 0 ? Math.round(((dt - di) * 100) / dt) : 0;
}

let memCache = { ts: 0, value: { total: 0, used: 0, pct: 0 } };

function readMem() {
    const now = Date.now();
    if (now - memCache.ts < MEM_TTL_MS) return memCache.value;

    let value = { total: 0, used: 0, pct: 0 };
    try {
        const m = fs.readFileSync('/proc/meminfo', 'utf8');
        const get = (key) => {
            const match = m.match(new RegExp(`^${key}:\\s+(\\d+)\\s+kB`, 'm'));
            return match ? parseInt(match[1], 10) * 1024 : 0;
        };
        const total = get('MemTotal');
        const avail = get('MemAvailable');
        value = { total, used: total - avail, pct: total ? Math.round(((total - avail) * 100) / total) : 0 };
    } catch {}
    memCache = { ts: now, value };
    return value;
}

const diskCache = new Map();

function readDisk(target) {
    const now = Date.now();
    const cached = diskCache.get(target);
    if (cached && now - cached.ts < DISK_TTL_MS) return cached.value;

    let value = { total: 0, used: 0, pct: 0 };
    try {
        if (typeof fs.statfsSync === 'function') {
            // One syscall instead of forking `df` on every sample.
            const s = fs.statfsSync(target);
            const total = s.blocks * s.bsize;
            const free = s.bavail * s.bsize;
            value = { total, used: total - free, pct: total ? Math.round(((total - free) * 100) / total) : 0 };
        } else {
            const out = execFileSync('df', ['-PB1', target], { encoding: 'utf8' });
            const cols = out.trim().split('\n')[1].split(/\s+/);
            const total = parseInt(cols[1], 10);
            const used = parseInt(cols[2], 10);
            value = { total, used, pct: total ? Math.round((used * 100) / total) : 0 };
        }
    } catch {}
    diskCache.set(target, { ts: now, value });
    return value;
}

let lastNet = null;

function readNet() {
    let rx = 0, tx = 0;
    try {
        const lines = fs.readFileSync('/proc/net/dev', 'utf8').split('\n').slice(2);
        for (const line of lines) {
            const match = line.trim().match(/^([^:]+):\s+(\d+)(?:\s+\d+){7}\s+(\d+)/);
            if (!match) continue;
            if (match[1].trim() === 'lo') continue;
            rx += parseInt(match[2], 10);
            tx += parseInt(match[3], 10);
        }
    } catch {}
    if (!lastNet) { lastNet = { rx, tx, ts: Date.now() }; return { rx_bps: 0, tx_bps: 0 }; }
    const dt = (Date.now() - lastNet.ts) / 1000;
    const value = {
        rx_bps: dt > 0 ? Math.round((rx - lastNet.rx) / dt) : 0,
        tx_bps: dt > 0 ? Math.round((tx - lastNet.tx) / dt) : 0,
    };
    lastNet = { rx, tx, ts: Date.now() };
    return value;
}

module.exports = { readCpu, readMem, readDisk, readNet, MEM_TTL_MS, DISK_TTL_MS };
