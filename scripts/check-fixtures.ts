import fs from 'node:fs';
import path from 'node:path';
import { decodeSiteGraph, SiteGraphVersion } from '../packages/schemas/src/sitegraph';

const root = process.cwd();
const fixtureDir = path.join(root, 'packages/fixtures/sitegraph');
const fixtures = [
  'modern-200a.json',
  'constrained-100a.json',
  'insufficient-data.json',
];

for (const file of fixtures) {
  const absolute = path.join(fixtureDir, file);
  const raw = fs.readFileSync(absolute, 'utf8');
  const parsed = decodeSiteGraph(JSON.parse(raw));
  if (parsed.schemaVersion !== SiteGraphVersion) {
    throw new Error(`${file}: expected schemaVersion ${SiteGraphVersion}, got ${parsed.schemaVersion}`);
  }
  if (!parsed.assessmentId) {
    throw new Error(`${file}: missing assessmentId`);
  }
}

console.log(`TypeScript fixture check passed for ${fixtures.length} SiteGraph files.`);
