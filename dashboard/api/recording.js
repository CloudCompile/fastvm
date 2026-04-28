// Screen recording endpoints. Thin wrapper around screen-recorder.sh.

'use strict';
const express = require('express');
const path = require('path');
const fs = require('fs');
const { execFile } = require('child_process');

const router = express.Router();
const SCRIPTS = process.env.FASTVM_SCRIPTS_DIR || '/fastvm-scripts';
const RECORDINGS = process.env.FASTVM_RECORDINGS_DIR || '/config/recordings';

const SAFE_LABEL = /^[A-Za-z0-9._-]{1,64}$/;
const SAFE_NAME = /^[0-9TZ_-]+-[A-Za-z0-9._-]+\.(mp4|webm|mkv)$/;

function run(args, cb) {
    execFile(path.join(SCRIPTS, 'screen-recorder.sh'), args, { timeout: 15000 }, cb);
}

router.get('/status', (_req, res) => {
    run(['status'], (err, stdout) => {
        if (err) return res.status(500).json({ error: err.message });
        const lines = stdout.trim().split('\n');
        res.json({ state: lines[0] || 'idle', file: lines[1] || null });
    });
});

router.post('/start', (req, res) => {
    const label = (req.body && req.body.label) || 'recording';
    if (!SAFE_LABEL.test(label)) return res.status(400).json({ error: 'invalid label' });
    run(['start', label], (err, _o, stderr) => {
        if (err) return res.status(500).json({ error: err.message, stderr });
        res.json({ ok: true });
    });
});

router.post('/stop', (_req, res) => {
    run(['stop'], (err, _o, stderr) => {
        if (err) return res.status(500).json({ error: err.message, stderr });
        res.json({ ok: true });
    });
});

router.get('/', (_req, res) => {
    fs.readdir(RECORDINGS, (err, files) => {
        if (err) return res.json([]);
        const out = (files || [])
            .filter((f) => /\.(mp4|webm|mkv)$/.test(f))
            .map((f) => {
                const st = fs.statSync(path.join(RECORDINGS, f));
                return { name: f, size: st.size, mtime: st.mtimeMs };
            })
            .sort((a, b) => b.mtime - a.mtime);
        res.json(out);
    });
});

router.get('/file/:name', (req, res) => {
    if (!SAFE_NAME.test(req.params.name)) return res.status(400).end();
    res.sendFile(path.join(RECORDINGS, req.params.name));
});

router.delete('/:name', (req, res) => {
    if (!SAFE_NAME.test(req.params.name)) return res.status(400).json({ error: 'invalid name' });
    try { fs.unlinkSync(path.join(RECORDINGS, req.params.name)); res.json({ ok: true }); }
    catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = { router };
