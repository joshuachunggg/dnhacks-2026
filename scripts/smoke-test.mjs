import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const requiredFiles = [
  'AGENTS.md',
  'README.md',
  'docs/PLAN.md',
  'docs/ARCHITECTURE.md',
  'docs/CONTRACTS.md',
  'docs/DECISIONS.md',
  'docs/DEMO.md',
  'docs/STATUS.md',
  'docs/HANDOFFS.md',
  'docs/SAFETY.md',
  'docs/TASKS.md',
  'research/SOURCES.md',
  'bugs/BUGS.md',
  '.env.example',
  '.gitignore',
  'pnpm-workspace.yaml',
  'packages/schemas/src/sitegraph.ts',
  'packages/fixtures/sitegraph/modern-200a.json',
  'packages/fixtures/sitegraph/constrained-100a.json',
  'packages/fixtures/sitegraph/insufficient-data.json',
  'scripts/smoke-test.mjs',
  'scripts/check-fixtures.ts',
  'scripts/check-fixtures.swift',
  'package.json',
  'pnpm-lock.yaml',
];

for (const relative of requiredFiles) {
  const absolute = path.join(root, relative);
  if (!fs.existsSync(absolute)) {
    throw new Error(`Missing required file: ${relative}`);
  }
}

const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const requiredScripts = ['dev', 'build', 'lint', 'typecheck', 'smoke', 'check'];
for (const script of requiredScripts) {
  if (!pkg.scripts || !pkg.scripts[script]) {
    throw new Error(`Missing package script: ${script}`);
  }
}

const page = fs.readFileSync(path.join(root, 'src/app/page.tsx'), 'utf8');
for (const phrase of ['SiteGraph v0', 'Assessment', 'modern 200 A']) {
  if (!page.includes(phrase)) {
    throw new Error(`Scaffold page is missing: ${phrase}`);
  }
}

const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
for (const phrase of ['spatial AI field-engineer demo', 'packages/schemas', 'pnpm fixtures:check']) {
  if (!readme.includes(phrase)) {
    throw new Error(`README is missing: ${phrase}`);
  }
}

console.log('Smoke check passed: scaffold files and scripts are present.');
