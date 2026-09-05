import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const requiredFiles = [
  'AGENTS.md',
  'README.md',
  'docs/ARCHITECTURE.md',
  'docs/DECISIONS.md',
  'docs/DEMO.md',
  'docs/TASKS.md',
  '.env.example',
  '.gitignore',
  'src/app/page.tsx',
  'src/app/layout.tsx',
  'scripts/smoke-test.mjs',
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
if (!page.includes('DNHacks project scaffold ready')) {
  throw new Error('Scaffold page copy is missing');
}

const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
for (const phrase of ['Pre-hackathon scaffold only.', 'Working hypothesis', 'pnpm smoke']) {
  if (!readme.includes(phrase)) {
    throw new Error(`README is missing: ${phrase}`);
  }
}

console.log('Smoke check passed: scaffold files and scripts are present.');
