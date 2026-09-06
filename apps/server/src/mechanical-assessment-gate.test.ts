import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { POST as appendEvent } from '../../../src/app/api/assessments/[assessmentId]/events/route';
import { POST as runGate } from '../../../src/app/api/assessments/[assessmentId]/assessment-gate/route';
import { SiteGraphVersion } from '../../../packages/schemas/src/sitegraph';

const fixture = JSON.parse(readFileSync(join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json'), 'utf8'));
const timestamp = '2026-09-06T12:00:00.000Z';
const context = { params: Promise.resolve({ assessmentId: fixture.assessmentId }) };

function event(eventName: string, payload: unknown) {
  return new Request(`http://localhost/api/assessments/${fixture.assessmentId}/events`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ eventId: `event-${eventName}-${Math.random()}`, eventName, timestamp, producer: 'test', schemaVersion: SiteGraphVersion, payload }),
  });
}

async function append(eventName: string, payload: unknown) {
  const response = await appendEvent(event(eventName, payload), context);
  assert.equal(response.status, 200, await response.text());
}

async function gate() {
  return runGate(new Request(`http://localhost/api/assessments/${fixture.assessmentId}/assessment-gate`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}',
  }), context);
}

test('mechanical gate returns one exact missing-input action and invokes engineering only after typed facts are complete', async () => {
  const created = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(fixture),
  }));
  assert.equal(created.status, 201);

  let response = await gate();
  let body = await response.json();
  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    gate: {
      status: 'needs_input',
      nextAction: 'capture_panel_image',
      message: 'Capture an electrical-panel image before confirming panel facts.',
    },
  });

  await append('visual.frame.recorded', {
    id: 'frame-gate-panel', coordinateSpaceId: 'room-space', timestamp, producer: 'test',
    artifact: { id: 'artifact-gate-panel', kind: 'panel_image', uri: 'file:///panel.jpg', contentType: 'image/jpeg', byteLength: 10, sha256: 'a'.repeat(64) },
    evidence: { id: 'evidence-gate-panel', type: 'image_frame', label: 'Panel image', uri: 'file:///panel.jpg' },
  });
  response = await gate();
  body = await response.json();
  assert.deepEqual(body.gate, {
    status: 'needs_input',
    nextAction: 'confirm_panel_facts',
    message: 'Ask for each missing panel fact and whether the user knows it or is approximating. A supplied approximation can support a planning-only deterministic result with a professional-verification disclaimer.',
  });
  await append('panel.facts.confirmed', {
    panelId: fixture.electricalPanel.id,
    facts: [
      { id: 'fact-service', field: 'service_amps', value: 200, unit: 'A', status: 'confirmed', sourceType: 'user_supplied', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', notes: ['User explicitly chose this planning approximation after the panel image could not verify the value. Professional verification remains required.'] },
      { id: 'fact-bus', field: 'bus_rating_amps', value: 200, unit: 'A', status: 'confirmed', sourceType: 'user_supplied', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', notes: [] },
      { id: 'fact-spare', field: 'spare_breaker_spaces', value: 4, status: 'confirmed', sourceType: 'user_supplied', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', notes: ['User explicitly chose this planning approximation after the panel image could not verify the value. Professional verification remains required.'] },
    ],
  });
  await append('spatial.location.confirmed', {
    id: 'location-panel', kind: 'electrical_panel', label: 'Panel', coordinateSpaceId: 'room-space', positionMeters: { x: 0, y: 0, z: 0 }, surface: 'wall', status: 'confirmed', sourceType: 'measured', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', assumptions: [], notes: [],
  });
  await append('spatial.location.confirmed', {
    id: 'location-evse', kind: 'evse', label: 'EVSE', coordinateSpaceId: 'room-space', positionMeters: { x: 3, y: 0, z: 4 }, surface: 'wall', status: 'confirmed', sourceType: 'measured', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', assumptions: [], notes: [],
  });

  response = await gate();
  body = await response.json();
  assert.equal(body.gate.nextAction, 'record_route_waypoints');
  assert.equal(body.assessment, undefined);

  await append('route.waypoints.recorded', {
    id: 'route-gate',
    waypoints: [
      { id: 'waypoint-1', sequence: 0, coordinateSpaceId: 'room-space', positionMeters: { x: 0, y: 0, z: 0 }, surface: 'wall', status: 'confirmed', sourceType: 'measured', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', assumptions: [], notes: [] },
      { id: 'waypoint-2', sequence: 1, coordinateSpaceId: 'room-space', positionMeters: { x: 3, y: 0, z: 4 }, surface: 'wall', status: 'confirmed', sourceType: 'measured', evidenceIds: ['evidence-gate-panel'], timestamp, producer: 'test', assumptions: [], notes: [] },
    ],
  });

  response = await gate();
  body = await response.json();
  assert.equal(body.gate.status, 'ready');
  assert.equal(body.gate.nextAction, 'finish_and_review');
  assert.equal(body.gate.planningOnly, true);
  assert.equal(body.gate.result.recommendation.chargerCurrentAmps, 32);
  assert.equal(body.assessment.measurements.at(-1).unit, 'ft');
  assert.equal(body.assessment.toolRuns.at(-1).toolName, 'runEngineeringScenario');
});
