/* FastVM dashboard client. Vanilla JS — no framework, no build step. */
(function () {
    'use strict';

    // ----- token / auth ---------------------------------------------------
    const STORAGE_KEY = 'fastvm.token';
    let token = localStorage.getItem(STORAGE_KEY) || '';

    const $ = (sel, root = document) => root.querySelector(sel);
    const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

    async function api(path, opts = {}) {
        const res = await fetch(path, {
            ...opts,
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { Authorization: 'Bearer ' + token } : {}),
                ...(opts.headers || {}),
            },
        });
        if (res.status === 401) { showLogin(); throw new Error('unauthorized'); }
        return res.json();
    }

    function showLogin() { $('#login').classList.remove('hidden'); }
    function hideLogin() { $('#login').classList.add('hidden'); }

    async function tryLogin(t) {
        const res = await fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ token: t }),
        });
        if (!res.ok) return false;
        token = t;
        localStorage.setItem(STORAGE_KEY, t);
        return true;
    }

    $('#login-btn').addEventListener('click', async () => {
        const t = $('#token-input').value.trim();
        if (!t) return;
        const ok = await tryLogin(t);
        if (ok) { hideLogin(); init(); }
        else { $('#token-input').style.borderColor = 'var(--danger)'; }
    });
    $('#token-input').addEventListener('keydown', (e) => {
        if (e.key === 'Enter') $('#login-btn').click();
    });

    // ----- view router ----------------------------------------------------
    $$('.nav').forEach((b) => {
        b.addEventListener('click', () => {
            $$('.nav').forEach((x) => x.classList.remove('active'));
            $$('.view').forEach((x) => x.classList.remove('active'));
            b.classList.add('active');
            $('#view-' + b.dataset.view).classList.add('active');
            if (b.dataset.view === 'snapshots') refreshSnapshots();
            if (b.dataset.view === 'recording') { refreshRecordings(); refreshRecStatus(); }
            if (b.dataset.view === 'tasks') refreshTasks();
            if (b.dataset.view === 'clipboard') pullClipboard();
        });
    });

    // ----- websocket metrics ---------------------------------------------
    const history = []; // ring of {ts, cpu, mem}
    const HISTORY_MAX = 720;

    function setBarFill(el, pct) {
        el.style.width = pct + '%';
        el.classList.toggle('warn', pct >= 70 && pct < 90);
        el.classList.toggle('danger', pct >= 90);
    }
    function fmtBytes(b) {
        if (!b) return '0 B';
        const u = ['B', 'KB', 'MB', 'GB', 'TB'];
        let i = 0; while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return b.toFixed(1) + ' ' + u[i];
    }

    function applyMetrics(m) {
        $('#m-cpu').textContent = m.cpu;
        setBarFill($('#bar-cpu'), m.cpu);

        $('#m-mem').textContent = m.mem.pct;
        $('#m-mem-detail').textContent = fmtBytes(m.mem.used) + ' / ' + fmtBytes(m.mem.total);
        setBarFill($('#bar-mem'), m.mem.pct);

        $('#m-disk').textContent = m.disk.pct;
        $('#m-disk-detail').textContent = fmtBytes(m.disk.used) + ' / ' + fmtBytes(m.disk.total);
        setBarFill($('#bar-disk'), m.disk.pct);

        $('#m-net-rx').textContent = Math.round(m.net.rx_bps / 1024);
        $('#m-net-tx').textContent = Math.round(m.net.tx_bps / 1024);

        history.push({ ts: m.ts, cpu: m.cpu, mem: m.mem.pct });
        while (history.length > HISTORY_MAX) history.shift();
        drawChart();
    }

    function drawChart() {
        const c = $('#chart-perf');
        if (!c) return;
        const ctx = c.getContext('2d');
        const w = c.width, h = c.height;
        ctx.clearRect(0, 0, w, h);

        // grid
        ctx.strokeStyle = 'rgba(94,242,200,0.06)';
        ctx.lineWidth = 1;
        for (let y = 0; y <= 100; y += 25) {
            const yy = h - (y / 100) * h;
            ctx.beginPath(); ctx.moveTo(0, yy); ctx.lineTo(w, yy); ctx.stroke();
        }
        if (history.length < 2) return;

        const drawSeries = (key, color) => {
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            ctx.beginPath();
            history.forEach((p, i) => {
                const x = (i / (history.length - 1)) * w;
                const y = h - (p[key] / 100) * h;
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            });
            ctx.stroke();

            const grad = ctx.createLinearGradient(0, 0, 0, h);
            grad.addColorStop(0, color + '40');
            grad.addColorStop(1, color + '00');
            ctx.fillStyle = grad;
            ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath();
            ctx.fill();
        };

        drawSeries('cpu', '#5ef2c8');
        drawSeries('mem', '#66b3ff');

        // legend
        ctx.fillStyle = '#5ef2c8';
        ctx.fillRect(12, 12, 10, 10);
        ctx.fillStyle = '#d6e1f0';
        ctx.font = '12px JetBrains Mono, monospace';
        ctx.fillText('CPU', 28, 22);
        ctx.fillStyle = '#66b3ff';
        ctx.fillRect(72, 12, 10, 10);
        ctx.fillStyle = '#d6e1f0';
        ctx.fillText('Memory', 88, 22);
    }

    let ws;
    function connectWs() {
        const proto = location.protocol === 'https:' ? 'wss' : 'ws';
        ws = new WebSocket(`${proto}://${location.host}/?token=${encodeURIComponent(token)}`);
        ws.onopen = () => {
            $('#ws-dot').classList.add('connected');
            $('#ws-dot').classList.remove('disconnected');
            $('#ws-state').textContent = 'live';
        };
        ws.onclose = () => {
            $('#ws-dot').classList.remove('connected');
            $('#ws-dot').classList.add('disconnected');
            $('#ws-state').textContent = 'reconnecting...';
            setTimeout(connectWs, 2000);
        };
        ws.onmessage = (ev) => {
            try {
                const msg = JSON.parse(ev.data);
                if (msg.type === 'metrics') applyMetrics(msg.data);
            } catch {}
        };
    }

    // ----- snapshots ------------------------------------------------------
    async function refreshSnapshots() {
        const data = await api('/api/snapshots');
        const tb = $('#snap-table tbody');
        tb.innerHTML = '';
        data.sort((a, b) => (b.created_unix || 0) - (a.created_unix || 0));
        for (const s of data) {
            const tr = document.createElement('tr');
            const created = s.created_unix ? new Date(s.created_unix * 1000).toLocaleString() : '—';
            tr.innerHTML = `
                <td>${s.archive}</td>
                <td>${s.label || '—'}</td>
                <td>${s.size_human || fmtBytes(s.size_bytes || 0)}</td>
                <td>${created}</td>
                <td>
                    <button data-action="restore" data-name="${s.archive}">Restore</button>
                    <button class="danger" data-action="delete" data-name="${s.archive}">Delete</button>
                </td>`;
            tb.appendChild(tr);
        }
    }
    $('#snap-create').addEventListener('click', async () => {
        const label = $('#snap-label').value.trim() || 'manual';
        await api('/api/snapshots', { method: 'POST', body: JSON.stringify({ label }) });
        $('#snap-label').value = '';
        refreshSnapshots();
    });
    $('#snap-refresh').addEventListener('click', refreshSnapshots);
    $('#snap-table').addEventListener('click', async (e) => {
        const btn = e.target.closest('button[data-action]');
        if (!btn) return;
        const { action, name } = btn.dataset;
        if (action === 'restore') {
            if (!confirm(`Restore ${name}? A safety snapshot will be created first.`)) return;
            await api(`/api/snapshots/${encodeURIComponent(name)}/restore`, { method: 'POST' });
            alert('Restore complete. Restart the container for full effect.');
        } else if (action === 'delete') {
            if (!confirm(`Delete ${name}? This cannot be undone.`)) return;
            await api(`/api/snapshots/${encodeURIComponent(name)}`, { method: 'DELETE' });
            refreshSnapshots();
        }
    });

    // ----- recording ------------------------------------------------------
    async function refreshRecStatus() {
        const s = await api('/api/recording/status');
        const pill = $('#rec-status');
        pill.textContent = s.state;
        pill.classList.toggle('recording', s.state === 'recording');
    }
    async function refreshRecordings() {
        const data = await api('/api/recording');
        const tb = $('#rec-table tbody');
        tb.innerHTML = '';
        for (const r of data) {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><a href="/api/recording/file/${encodeURIComponent(r.name)}?token=${encodeURIComponent(token)}" target="_blank">${r.name}</a></td>
                <td>${fmtBytes(r.size)}</td>
                <td>${new Date(r.mtime).toLocaleString()}</td>
                <td><button class="danger" data-action="del" data-name="${r.name}">Delete</button></td>`;
            tb.appendChild(tr);
        }
    }
    $('#rec-start').addEventListener('click', async () => {
        const label = $('#rec-label').value.trim() || 'recording';
        await api('/api/recording/start', { method: 'POST', body: JSON.stringify({ label }) });
        refreshRecStatus();
    });
    $('#rec-stop').addEventListener('click', async () => {
        await api('/api/recording/stop', { method: 'POST' });
        refreshRecStatus();
        refreshRecordings();
    });
    $('#rec-table').addEventListener('click', async (e) => {
        const btn = e.target.closest('button[data-action="del"]');
        if (!btn) return;
        if (!confirm('Delete recording?')) return;
        await api(`/api/recording/${encodeURIComponent(btn.dataset.name)}`, { method: 'DELETE' });
        refreshRecordings();
    });

    // ----- tasks ----------------------------------------------------------
    async function refreshTasks() {
        const data = await api('/api/tasks');
        const tb = $('#task-table tbody');
        tb.innerHTML = '';
        for (const t of (data.tasks || [])) {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${t.id}</td>
                <td>${t.schedule}</td>
                <td>${t.command}</td>
                <td>${t.enabled ? 'enabled' : 'disabled'}</td>
                <td>
                    <button data-action="toggle" data-id="${t.id}" data-on="${t.enabled}">${t.enabled ? 'Disable' : 'Enable'}</button>
                    <button class="danger" data-action="del" data-id="${t.id}">Delete</button>
                </td>`;
            tb.appendChild(tr);
        }
    }
    $('#task-create').addEventListener('click', async () => {
        const id = $('#task-id').value.trim();
        const schedule = $('#task-schedule').value.trim();
        const command = $('#task-command').value.trim();
        if (!id || !schedule || !command) return;
        await api('/api/tasks', { method: 'POST', body: JSON.stringify({ id, schedule, command }) });
        $('#task-id').value = $('#task-schedule').value = $('#task-command').value = '';
        refreshTasks();
    });
    $('#task-table').addEventListener('click', async (e) => {
        const btn = e.target.closest('button[data-action]');
        if (!btn) return;
        const { action, id, on } = btn.dataset;
        if (action === 'toggle') {
            const route = on === 'true' ? 'disable' : 'enable';
            await api(`/api/tasks/${encodeURIComponent(id)}/${route}`, { method: 'POST' });
        } else if (action === 'del') {
            if (!confirm(`Delete task ${id}?`)) return;
            await api(`/api/tasks/${encodeURIComponent(id)}`, { method: 'DELETE' });
        }
        refreshTasks();
    });

    // ----- clipboard ------------------------------------------------------
    async function pullClipboard() {
        const data = await api('/api/clipboard');
        $('#clip-text').value = data.content || '';
    }
    async function pushClipboard() {
        await api('/api/clipboard', { method: 'POST', body: JSON.stringify({ content: $('#clip-text').value }) });
    }
    $('#clip-pull').addEventListener('click', pullClipboard);
    $('#clip-push').addEventListener('click', pushClipboard);

    // ----- init -----------------------------------------------------------
    async function init() {
        connectWs();
        // Prime values until first WS frame arrives.
        try { applyMetrics(await api('/api/performance/current')); } catch {}
    }

    if (token) {
        tryLogin(token).then((ok) => { if (ok) { hideLogin(); init(); } else { showLogin(); } });
    } else {
        showLogin();
    }
})();
