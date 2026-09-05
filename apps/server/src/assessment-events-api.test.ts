import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { POST } from '../../../src/app/api/assessments/[assessmentId]/events/route';
import { SiteGraphVersion } from '../../../packages/schemas/src/sitegraph';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'));

const event = {
  eventId: 'event-ios-confirmed-panel-label',
  eventName: 'observation.added',
  timestamp: '2026-09-05T12:00:00.000Z',
  producer: 'ios-demo',
  schemaVersion: SiteGraphVersion,
  payload: {
    id: 'obs-ios-confirmed-panel-label',
    kind: 'label_text',
    field: 'panel_label_confirmation',
    value: 'Panel label confirmed by user',
    status: 'confirmed',
    sourceType: 'user_supplied',
    confidence: 1,
    evidenceIds: ['evidence-panel-fixture'],
    timestamp: '2026-09-05T12:00:00.000Z',
    producer: 'ios-demo',
    assumptions: [],
    notes: ['Confirmed during the guided demo.'],
  },
};

test('POST /api/assessments/:id/events validates and persists an observation.added event', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));
  assert.equal(createResponse.status, 201);

  const response = await POST(
    new Request(`http://localhost/api/assessments/${fixture.assessmentId}/events`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(event),
    }),
    { params: Promise.resolve({ assessmentId: fixture.assessmentId }) },
  );

  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.assessment.observations.at(-1).id, event.payload.id);
});
