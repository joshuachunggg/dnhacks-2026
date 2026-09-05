import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { GET } from '../../../src/app/api/assessments/[assessmentId]/route';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'));

test('GET /api/assessments/:id returns the assessment created by the API', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));
  assert.equal(createResponse.status, 201);

  const response = await GET(
    new Request(`http://localhost/api/assessments/${fixture.assessmentId}`),
    { params: Promise.resolve({ assessmentId: fixture.assessmentId }) },
  );

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { assessment: fixture });
});
