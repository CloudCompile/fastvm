// Snapshot REST endpoints. Shells out to the backup-* scripts.

'use strict';
const express = require('express');
const path = require('path');
const fs = require('fs');
const { execFile } = require('child_process');

const router = express.Router();
const SCRIPTS = process.env.FASTVM_SCRIPTS_DIR || '/fastvm-scripts';
const BACKUP_DIR = process.env.FASTVM_BACKUP_DIR || '/config/backups';

function safeBaseName(name) {
    // Reject path traversal; archives are flat files in BACKUP_DIR.
    return /^fastvm-[A-Za-z0-9._-]+\.tar\.(gz|xz|zst)$/.test(name) ? name : null;
}

function runScript(script, args, cb) {
    execFile(path.join(SCRIPTS, script), args, { timeout: 10 * 60 * 1000 }, cb);
}

router.get('/', (_req, res) => {
    runScript('backup-list.sh', ['--json'], (err, stdout) => {
        if (err) return res.status(500).json({ error: err.message });
        try { return res.json(JSON.parse(stdout)); }
        catch { return res.status(500).json({ error: 'parse error', raw: stdout }); }
    });
});

router.post('/', (req, res) => {
    const label = (req.body && req.body.label) || 'manual';
    runScript('backup-create.sh', [label], (err, stdout, stderr) => {
        if (err) return res.status(500).json({ error: err.message, stderr });
        res.json({ ok: true, archive: stdout.trim() });
    });
});

router.post('/:name/restore', (req, res) => {
    const name = safeBaseName(req.params.name);
    if (!name) return res.status(400).json({ error: 'invalid archive name' });
    runScript('backup-restore.sh', [name], (err, stdout, stderr) => {
        if (err) return res.status(500).json({ error: err.message, stderr });
        res.json({ ok: true, output: stdout });
    });
});

router.delete('/:name', (req, res) => {
    const name = safeBaseName(req.params.name);
    if (!name) return res.status(400).json({ error: 'invalid archive name' });
    const archive = path.join(BACKUP_DIR, name);
    try {
        fs.unlinkSync(archive);
        try { fs.unlinkSync(archive + '.json'); } catch {}
        res.json({ ok: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = { router };
