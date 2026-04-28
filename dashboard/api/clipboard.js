// Bidirectional clipboard sync. The shell daemon mirrors X11 -> file;
// browser pushes here to update the file (which the daemon then mirrors back
// into the X11 selection).

'use strict';
const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const DATA_ROOT = process.env.FASTVM_DATA_ROOT || '/config';
const FILE = path.join(DATA_ROOT, '.fastvm', 'clipboard.txt');
const MAX_BYTES = 10 * 1024 * 1024;

router.get('/', (_req, res) => {
    fs.readFile(FILE, 'utf8', (err, content) => {
        if (err) return res.json({ content: '' });
        res.json({ content });
    });
});

router.post('/', (req, res) => {
    const content = (req.body && req.body.content) || '';
    if (Buffer.byteLength(content, 'utf8') > MAX_BYTES) {
        return res.status(413).json({ error: 'too large (>10MB)' });
    }
    fs.mkdirSync(path.dirname(FILE), { recursive: true });
    fs.writeFile(FILE, content, (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ ok: true });
    });
});

module.exports = { router };
