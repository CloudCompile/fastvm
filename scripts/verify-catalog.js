#!/usr/bin/env node
'use strict';

/**
 * Verify that the desktop and preset lists in the Rust catalog stay in sync with
 * the build matrix in .github/workflows/build-images.yml.
 *
 * Usage:
 *   node scripts/verify-catalog.js          # human-readable report
 *   node scripts/verify-catalog.js --json    # machine-readable
 *
 * Exit code 0 when in sync, 1 when there is drift.
 */

const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const WORKFLOW = path.join(ROOT, '.github', 'workflows', 'build-images.yml');
const CATALOG_RS = path.join(ROOT, 'desktop-app', 'src-tauri', 'src', 'catalog.rs');

/** Extract a `key:` list from the workflow matrix (indentation based). */
function extractMatrixList(text, key) {
  const lines = text.split('\n');
  const out = [];
  let inList = false;
  let indent = 0;
  for (const line of lines) {
    const start = line.match(new RegExp(`^(\\s*)${key}:\\s*$`));
    if (start) { inList = true; indent = start[1].length; continue; }
    if (inList) {
      const item = line.match(/^\s*-\s+(\S+)\s*$/);
      if (item) { out.push(item[1]); continue; }
      if (/^\s*\S/.test(line) && line.search(/\S/) <= indent) break;
    }
  }
  return out;
}

/** Extract quoted string literals from a `pub const NAME: &[&str] = &[ ... ];` block. */
function extractRustList(text, constName) {
  const start = text.indexOf(`pub const ${constName}`);
  if (start === -1) return null;
  const open = text.indexOf('[', start);
  const close = text.indexOf('];', open);
  if (open === -1 || close === -1) return null;
  const body = text.slice(open + 1, close);
  return [...body.matchAll(/"([^"]+)"/g)].map((m) => m[1]);
}

/** Every `FASTVM_OS_FLAVOR=<value>` build-arg in the workflow. */
function extractFlavorArgs(text) {
  return [...text.matchAll(/FASTVM_OS_FLAVOR=([a-z0-9-]+)/g)].map((m) => m[1]);
}

/** `- name: <value>` entries inside the build-specials `matrix.include` block. */
function extractSpecials(text) {
  const start = text.indexOf('build-specials:');
  if (start === -1) return [];
  const end = text.indexOf('\n  build-', start + 1);
  const block = text.slice(start, end === -1 ? undefined : end);
  return [...block.matchAll(/^\s*-\s*name:\s*([a-z0-9-]+)\s*$/gm)].map((m) => m[1]);
}

function compare(actual, expected, label) {
  const missing = expected.filter((v) => !actual.includes(v));
  const extra = actual.filter((v) => !expected.includes(v));
  return { label, missing, extra, count: actual.length, ok: missing.length === 0 && extra.length === 0 };
}

function main() {
  const workflow = fs.readFileSync(WORKFLOW, 'utf8');
  const rust = fs.readFileSync(CATALOG_RS, 'utf8');

  const checks = [
    compare(extractRustList(rust, 'DESKTOPS') || [], extractMatrixList(workflow, 'desktop'), 'desktops'),
    compare(extractRustList(rust, 'PRESETS') || [], extractMatrixList(workflow, 'preset'), 'presets'),
    compare(extractRustList(rust, 'FLAVORS') || [], extractFlavorArgs(workflow), 'flavors'),
    compare(extractRustList(rust, 'SINGLE_APPS') || [], extractSpecials(workflow), 'single apps'),
  ];

  const mismatches = checks.filter((c) => !c.ok);
  const report = { ok: mismatches.length === 0, checks, mismatches };

  if (process.argv.includes('--json')) {
    process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  } else {
    for (const c of checks) {
      if (c.ok) console.log(`[ OK ] ${c.label}: in sync (${c.count})`);
      else {
        console.log(`[FAIL] ${c.label}`);
        if (c.missing.length) console.log(`       missing from catalog: ${c.missing.join(', ')}`);
        if (c.extra.length) console.log(`       not in workflow: ${c.extra.join(', ')}`);
      }
    }
  }

  process.exit(report.ok ? 0 : 1);
}

main();
