'use strict';

const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();

const DATA_ROOT = process.env.FASTVM_DATA_ROOT || '/config';
const ANALYTICS_FILE = path.join(DATA_ROOT, '.fastvm', 'analytics.json');

// Initialize analytics file if it doesn't exist
function ensureAnalyticsFile() {
  const dir = path.dirname(ANALYTICS_FILE);
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch (e) {
    // ignore
  }

  if (!fs.existsSync(ANALYTICS_FILE)) {
    const initial = {
      containerStarted: new Date().toISOString(),
      totalSessions: 1,
      activeSessionCount: 0,
      lastActivityTime: new Date().toISOString(),
      sessionHistory: [
        {
          startTime: new Date().toISOString(),
          endTime: null,
          duration: 0,
        },
      ],
    };
    try {
      fs.writeFileSync(ANALYTICS_FILE, JSON.stringify(initial, null, 2), 'utf8');
    } catch (e) {
      console.error(`[analytics] failed to write analytics file: ${e.message}`);
    }
  }
}

function readAnalytics() {
  try {
    ensureAnalyticsFile();
    const data = fs.readFileSync(ANALYTICS_FILE, 'utf8');
    return JSON.parse(data);
  } catch (e) {
    console.error(`[analytics] failed to read analytics: ${e.message}`);
    return {
      containerStarted: new Date().toISOString(),
      totalSessions: 1,
      activeSessionCount: 1,
      lastActivityTime: new Date().toISOString(),
      sessionHistory: [],
    };
  }
}

function writeAnalytics(data) {
  try {
    ensureAnalyticsFile();
    fs.writeFileSync(ANALYTICS_FILE, JSON.stringify(data, null, 2), 'utf8');
  } catch (e) {
    console.error(`[analytics] failed to write analytics: ${e.message}`);
  }
}

// Track session activity
let sessionId = null;
let sessionStartTime = null;

function trackSessionStart() {
  sessionId = `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  sessionStartTime = Date.now();

  const analytics = readAnalytics();
  analytics.totalSessions += 1;
  analytics.activeSessionCount = (analytics.activeSessionCount || 0) + 1;
  analytics.lastActivityTime = new Date().toISOString();

  analytics.sessionHistory.push({
    id: sessionId,
    startTime: new Date().toISOString(),
    endTime: null,
    duration: 0,
  });

  writeAnalytics(analytics);
  console.log(`[analytics] session started: ${sessionId} (active: ${analytics.activeSessionCount})`);
}

function trackSessionEnd() {
  if (!sessionId) return;

  const analytics = readAnalytics();
  analytics.activeSessionCount = Math.max(0, (analytics.activeSessionCount || 1) - 1);
  analytics.lastActivityTime = new Date().toISOString();

  const session = analytics.sessionHistory.find(s => s.id === sessionId);
  if (session) {
    session.endTime = new Date().toISOString();
    session.duration = Math.floor((Date.now() - sessionStartTime) / 1000);
  }

  writeAnalytics(analytics);
  console.log(`[analytics] session ended: ${sessionId} (active: ${analytics.activeSessionCount})`);
  sessionId = null;
}

// Middleware to track activity
function trackActivity(req, res, next) {
  if (!sessionId) {
    trackSessionStart();
  }

  const analytics = readAnalytics();
  analytics.lastActivityTime = new Date().toISOString();
  writeAnalytics(analytics);

  next();
}

// Routes
router.get('/stats', (req, res) => {
  const analytics = readAnalytics();

  // Calculate uptime from container start
  const containerStart = new Date(analytics.containerStarted).getTime();
  const uptime = Math.floor((Date.now() - containerStart) / 1000);

  res.json({
    ok: true,
    containerStarted: analytics.containerStarted,
    totalSessions: analytics.totalSessions,
    activeSessionCount: Math.max(0, analytics.activeSessionCount),
    lastActivityTime: analytics.lastActivityTime,
    uptime: uptime,
    uptimeFormatted: formatUptime(uptime),
  });
});

router.get('/summary', (req, res) => {
  const analytics = readAnalytics();
  const containerStart = new Date(analytics.containerStarted).getTime();
  const uptime = Math.floor((Date.now() - containerStart) / 1000);

  // Calculate average session duration
  const completedSessions = analytics.sessionHistory.filter(s => s.endTime);
  const avgDuration = completedSessions.length > 0
    ? Math.floor(completedSessions.reduce((sum, s) => sum + (s.duration || 0), 0) / completedSessions.length)
    : 0;

  res.json({
    ok: true,
    stats: {
      containerUptime: formatUptime(uptime),
      totalSessions: analytics.totalSessions,
      activeSessions: Math.max(0, analytics.activeSessionCount),
      averageSessionDuration: formatUptime(avgDuration),
      lastActivity: analytics.lastActivityTime,
    },
  });
});

function formatUptime(seconds) {
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
  return `${Math.floor(seconds / 86400)}d`;
}

module.exports = {
  router,
  trackActivity,
  trackSessionStart,
  trackSessionEnd,
};
