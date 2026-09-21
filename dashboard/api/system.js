'use strict';

const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const DATA_ROOT = process.env.FASTVM_DATA_ROOT || '/config';
const STATE_DIR = path.join(DATA_ROOT, '.fastvm');
const ACTION_FILE = path.join(STATE_DIR, 'system-action.json');

function readAction() {
    try { return JSON.parse(fs.readFileSync(ACTION_FILE, 'utf8')); } catch { return null; }
}

function requestAction(type, res) {
    fs.mkdirSync(STATE_DIR, { recursive: true });
    const action = { type, requested_at: new Date().toISOString(), status: 'requested' };
    fs.writeFileSync(ACTION_FILE, JSON.stringify(action, null, 2) + '\n', { mode: 0o600 });
    return res.status(202).json({ ok: true, action });
}

router.get('/status', (_req, res) => res.json({
    ok: true,
    version: process.env.FASTVM_VERSION || 'dev',
    desktop: process.env.FASTVM_DE || 'XFCE4',
    preset: process.env.FASTVM_PRESET || 'none',
    pending_action: readAction(),
}));

router.post('/recovery', (_req, res) => requestAction('recovery', res));
router.post('/update', (_req, res) => requestAction('update', res));

module.exports = { router };