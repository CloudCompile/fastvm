// Performance metrics: CPU%, memory, disk usage, network.
//
// Sampling and broadcast are decoupled: history is filled by the broadcast
// loop, which only runs work while at least one WebSocket client is connected,
// and a reading is reused for a short window so concurrent REST requests and
// the broadcaster share one /proc pass instead of each doing their own.

'use strict';
const express = require('express');
const gpu = require('./gpu');
const { readCpu, readMem, readDisk, readNet } = require('./perf-core');

const router = express.Router();
const HISTORY_LEN = 120; // ~10 min at the 5s broadcast cadence

const history = [];
let lastSample = null;
let lastSampleAtMs = 0;
let lastHistoryAtMs = 0;

function sample() {
    const ts = Date.now();
    const value = {
        ts,
        cpu: readCpu(),
        mem: readMem(),
        disk: readDisk(process.env.FASTVM_DATA_ROOT || '/config'),
        backups: readDisk(process.env.FASTVM_BACKUP_DIR || '/config/backups'),
        net: readNet(),
        gpu: gpu.readGpu(),
    };
    lastSample = value;
    lastSampleAtMs = ts;
    return value;
}

// Reuse a fresh reading (within half a broadcast interval) so a REST request
// landing in the same tick as the broadcaster does not re-read /proc.
function currentSample() {
    const now = Date.now();
    if (lastSample && now - lastSampleAtMs < 2500) return lastSample;
    return sample();
}

// Append to history at most once per broadcast interval, so REST polling
// cannot flood the ring buffer.
function tick() {
    const now = Date.now();
    if (lastSample && now - lastHistoryAtMs < 4500) return lastSample;
    const value = sample();
    lastHistoryAtMs = now;
    history.push(value);
    if (history.length > HISTORY_LEN) history.shift();
    return value;
}

router.get('/current', (_req, res) => res.json(currentSample()));
router.get('/history', (_req, res) => res.json(history));

function startBroadcaster(wss, intervalMs) {
    const id = setInterval(() => {
        // Nothing to compute or send when nobody is listening.
        const clients = [];
        for (const client of wss.clients) {
            if (client.readyState === 1) clients.push(client);
        }
        if (clients.length === 0) return;

        const payload = JSON.stringify({ type: 'metrics', data: tick() });
        for (const client of clients) client.send(payload);
    }, intervalMs);
    return () => clearInterval(id);
}

module.exports = { router, startBroadcaster };
