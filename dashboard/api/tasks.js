// Scheduled-task REST endpoints. Wraps task-manager.sh.

'use strict';
const express = require('express');
const path = require('path');
const { execFile } = require('child_process');

const router = express.Router();
const SCRIPTS = process.env.FASTVM_SCRIPTS_DIR || '/fastvm-scripts';

const SAFE_ID = /^[A-Za-z0-9._-]{1,64}$/;
// Whitelist cron schedule expressions. Allows digits, *, /, -, comma, space.
const SAFE_SCHEDULE = /^[\d\*\/\,\-\s@a-z]+$/i;

function run(args, cb) {
    execFile(path.join(SCRIPTS, 'task-manager.sh'), args, { timeout: 30000 }, cb);
}

router.get('/', (_req, res) => {
    run(['list', '--json'], (err, stdout) => {
        if (err) return res.status(500).json({ error: err.message });
        try { return res.json(JSON.parse(stdout)); }
        catch { return res.status(500).json({ error: 'parse error' }); }
    });
});

router.post('/', (req, res) => {
    const { id, schedule, command } = req.body || {};
    if (!SAFE_ID.test(id || '')) return res.status(400).json({ error: 'invalid id' });
    if (!SAFE_SCHEDULE.test(schedule || '')) return res.status(400).json({ error: 'invalid schedule' });
    if (!command || command.length > 1024) return res.status(400).json({ error: 'invalid command' });
    run(['add', id, schedule, command], (err, _o, stderr) => {
        if (err) return res.status(500).json({ error: err.message, stderr });
        res.json({ ok: true });
    });
});

router.post('/:id/enable', (req, res) => {
    if (!SAFE_ID.test(req.params.id)) return res.status(400).json({ error: 'invalid id' });
    run(['enable', req.params.id], (err) => err ? res.status(500).json({ error: err.message }) : res.json({ ok: true }));
});

router.post('/:id/disable', (req, res) => {
    if (!SAFE_ID.test(req.params.id)) return res.status(400).json({ error: 'invalid id' });
    run(['disable', req.params.id], (err) => err ? res.status(500).json({ error: err.message }) : res.json({ ok: true }));
});

router.delete('/:id', (req, res) => {
    if (!SAFE_ID.test(req.params.id)) return res.status(400).json({ error: 'invalid id' });
    run(['remove', req.params.id], (err) => err ? res.status(500).json({ error: err.message }) : res.json({ ok: true }));
});

module.exports = { router };
