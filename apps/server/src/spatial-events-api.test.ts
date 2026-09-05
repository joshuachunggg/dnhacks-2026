import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { POST } from '../../../src/app/api/assessments/[assessmentId]/events/route';
import { SiteGraphVersion } from '../../../packages/schemas/src/sitegraph';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'));

async function postEvent(event: unknown): Promise<Response> {
  return POST(
    new Request(`http://localhost/api/assessments/${fixture.assessmentId}/events`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(event),
    }),
    { params: Promise.resolve({ assessmentId: fixture.assessmentId }) },
  );
}

test('POST /api/assessments/:id/events persists a RoomPlan manifest and confirmed spatial facts', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));
  assert.equal(createResponse.status, 201);

  const captureResponse = await postEvent({
    eventId: 'event-roomplan-captured',
    eventName: 'spatial.capture.recorded',
    timestamp: '2026-09-05T14:00:00.000Z',
    producer: 'ios-roomplan',
    schemaVersion: SiteGraphVersion,
    payload: {
      id: 'capture-garage-001',
      kind: 'roomplan_room',
      status: 'confirmed',
      coordinateSpaceId: 'roomplan-session-001',
      timestamp: '2026-09-05T14:00:00.000Z',
      producer: 'ios-roomplan',
      artifacts: [
        {
          id: 'artifact-garage-usdz',
          kind: 'room_usdz',
          uri: 'file:///captures/capture-garage-001.usdz',
          contentType: 'model/vnd.usdz+zip',
          byteLength: 2048,
          sha256: 'a'.repeat(64),
        },
      ],
      evidence: [
        {
          id: 'evidence-garage-roomplan',
          type: 'room_model',
          label: 'Garage RoomPlan capture',
          uri: 'file:///captures/capture-garage-001.usdz',
        },
      ],
    },
  });
  assert.equal(captureResponse.status, 200);

  const measurementResponse = await postEvent({
    eventId: 'event-route-recorded',
    eventName: 'measurement.recorded',
    timestamp: '2026-09-05T14:01:00.000Z',
    producer: 'ios-roomplan',
    schemaVersion: SiteGraphVersion,
    payload: {
      id: 'measurement-garage-route-001',
      kind: 'route_length',
      value: 28.5,
      unit: 'ft',
      status: 'confirmed',
      sourceType: 'measured',
      confidence: 0.8,
      evidenceIds: ['evidence-garage-roomplan'],
      timestamp: '2026-09-05T14:01:00.000Z',
      producer: 'ios-roomplan',
      assumptions: ['Measured within the captured garage coordinate space.'],
      notes: [],
    },
  });
  assert.equal(measurementResponse.status, 200);

  const locationResponse = await postEvent({
    eventId: 'event-evse-location-confirmed',
    eventName: 'evse_location.confirmed',
    timestamp: '2026-09-05T14:02:00.000Z',
    producer: 'ios-roomplan',
    schemaVersion: SiteGraphVersion,
    payload: {
      id: 'evse-location-garage-west',
      label: 'Garage west wall',
      wall: 'garage west wall',
      status: 'confirmed',
      sourceType: 'measured',
      confidence: 0.8,
      evidenceIds: ['evidence-garage-roomplan'],
      timestamp: '2026-09-05T14:02:00.000Z',
      producer: 'ios-roomplan',
      assumptions: ['Anchor is a proposed installation location, not an electrical approval.'],
      notes: ['Confirmed by the homeowner.'],
    },
  });
  assert.equal(locationResponse.status, 200);

  const body = await locationResponse.json();
  assert.equal(body.assessment.spatialCaptures[0].id, 'capture-garage-001');
  assert.equal(body.assessment.spatialCaptures[0].artifacts[0].kind, 'room_usdz');
  assert.equal(body.assessment.evidence.at(-1).id, 'evidence-garage-roomplan');
  assert.equal(body.assessment.measurements.at(-1).id, 'measurement-garage-route-001');
  assert.equal(body.assessment.proposedEvseLocation.id, 'evse-location-garage-west');
});

test('POST /api/assessments/:id/events rejects a spatial capture without a valid artifact hash', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));
  assert.equal(createResponse.status, 201);

  const response = await postEvent({
    eventId: 'event-invalid-roomplan-captured',
    eventName: 'spatial.capture.recorded',
    timestamp: '2026-09-05T14:00:00.000Z',
    producer: 'ios-roomplan',
    schemaVersion: SiteGraphVersion,
    payload: {
      id: 'capture-garage-invalid',
      kind: 'roomplan_room',
      status: 'confirmed',
      coordinateSpaceId: 'roomplan-session-invalid',
      timestamp: '2026-09-05T14:00:00.000Z',
      producer: 'ios-roomplan',
      artifacts: [{
        id: 'artifact-garage-invalid',
        kind: 'room_usdz',
        uri: 'file:///captures/capture-garage-invalid.usdz',
        contentType: 'model/vnd.usdz+zip',
        byteLength: 2048,
        sha256: 'not-a-sha256',
      }],
      evidence: [{
        id: 'evidence-garage-invalid',
        type: 'room_model',
        label: 'Invalid garage RoomPlan capture',
      }],
    },
  });

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'validation_error');
});
