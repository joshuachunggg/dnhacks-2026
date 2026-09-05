import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { decodeSiteGraph } from '../../../packages/schemas/src/sitegraph';

const iosFixturePath = join(process.cwd(), 'apps/ios/Resources/modern-200a.json');

test('the bundled iOS modern-200a fixture satisfies the canonical SiteGraph schema', () => {
  const fixture = JSON.parse(readFileSync(iosFixturePath, 'utf8'));
  const decoded = decodeSiteGraph(fixture);

  assert.equal(decoded.assessmentId, 'assessment-modern-200a');
  assert.ok(Array.isArray(decoded.toolRuns));
});
