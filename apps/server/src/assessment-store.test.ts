import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { decodeSiteGraph, SiteGraphVersion } from '../../../packages/schemas/src/sitegraph';
import {
  AssessmentNotFoundError,
  createInMemoryAssessmentStore,
} from './assessment-store';
import { runEngineeringScenario } from './engineering-calculator';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = decodeSiteGraph(JSON.parse(readFileSync(fixturePath, 'utf8')));

function observationAddedEvent() {
  return {
    eventId: 'event-breaker-label-confirmed',
    eventName: 'observation.added',
    timestamp: '2026-09-05T12:00:00.000Z',
    producer: 'ios-demo',
    schemaVersion: SiteGraphVersion,
    payload: {
      id: 'obs-breaker-label-confirmed',
      kind: 'label_text',
      field: 'breaker_label_30a',
      value: 'EVSE circuit label confirmed by user',
      status: 'confirmed',
      sourceType: 'user_supplied',
      confidence: 1,
      evidenceIds: ['evidence-panel-fixture'],
      timestamp: '2026-09-05T12:00:00.000Z',
      producer: 'ios-demo',
      assumptions: [],
      notes: ['Confirmed during guided demo.'],
    },
  };
}

test('stores a validated assessment and returns it after a valid observation.added event', () => {
  const store = createInMemoryAssessmentStore();
  const created = store.create(fixture);

  const updated = store.appendObservationEvent(created.assessmentId, observationAddedEvent());

  assert.equal(updated.assessmentId, fixture.assessmentId);
  assert.equal(updated.observations.length, fixture.observations.length + 1);
  assert.deepEqual(updated.observations.at(-1), observationAddedEvent().payload);
});

test('rejects an invalid observation.added payload without mutating the stored assessment', () => {
  const store = createInMemoryAssessmentStore();
  const created = store.create(fixture);

  assert.throws(
    () => store.appendObservationEvent(created.assessmentId, {
      ...observationAddedEvent(),
      payload: { ...observationAddedEvent().payload, field: undefined },
    }),
  );

  assert.equal(store.get(created.assessmentId)?.observations.length, fixture.observations.length);
});

test('reports a missing assessment instead of silently creating one', () => {
  const store = createInMemoryAssessmentStore();

  assert.throws(
    () => store.appendObservationEvent('missing-assessment', observationAddedEvent()),
    AssessmentNotFoundError,
  );
});

test('atomically persists a canonical engineering scenario result', () => {
  const store = createInMemoryAssessmentStore();
  const created = store.create(fixture);
  const result = runEngineeringScenario(created, '2030-01-02T03:04:05.000Z');

  const updated = store.applyEngineeringScenario(created.assessmentId, result);

  assert.equal(updated.toolRuns.at(-1)?.id, result.toolRun.id);
  assert.equal(updated.engineeringScenarios.at(-1)?.id, `engineering-scenario-${created.assessmentId}`);
  assert.equal(store.get(created.assessmentId)?.toolRuns.at(-1)?.timestamp, result.toolRun.timestamp);
});

test('uses the supplied engineering calculation timestamp when applying a result', () => {
  const store = createInMemoryAssessmentStore();
  const created = store.create(fixture);
  const result = runEngineeringScenario(created, '2030-01-02T03:04:05.000Z');

  assert.throws(
    () => store.applyEngineeringScenario(created.assessmentId, result, '2030-01-02T03:04:06.000Z'),
    /trusted calculation timestamp/i,
  );
});
