import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST } from '../../../src/app/api/assessments/route';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'));

test('POST /api/assessments stores a validated assessment and returns it', async () => {
  const response = await POST(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));

  assert.equal(response.status, 201);
  assert.deepEqual(await response.json(), { assessment: fixture });
});
