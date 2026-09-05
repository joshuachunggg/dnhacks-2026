import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { POST } from '../../../src/app/api/assessments/[assessmentId]/tools/runEngineeringScenario/route';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'));
const insufficientFixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/insufficient-data.json');
const insufficientFixture = JSON.parse(readFileSync(insufficientFixturePath, 'utf8'));

function context(assessmentId: string) {
  return { params: Promise.resolve({ assessmentId }) };
}

test('POST /api/assessments/:id/tools/runEngineeringScenario calculates and persists the canonical scenario', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));
  assert.equal(createResponse.status, 201);

  const response = await POST(
    new Request(`http://localhost/api/assessments/${fixture.assessmentId}/tools/runEngineeringScenario`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{}',
    }),
    context(fixture.assessmentId),
  );

  assert.equal(response.status, 200);
  const { assessment } = await response.json();
  assert.equal(assessment.toolRuns.at(-1).toolName, 'runEngineeringScenario');
  assert.equal(assessment.engineeringScenarios.at(-1).chargerCurrentAmps, 32);
  assert.match(assessment.toolRuns.at(-1).timestamp, /^\d{4}-\d{2}-\d{2}T/);
  assert.equal(assessment.toolRuns.at(-1).output.origin.calculationTimestamp, assessment.toolRuns.at(-1).timestamp);
});

test('POST /api/assessments/:id/tools/runEngineeringScenario rejects invalid JSON and client-supplied output', async () => {
  const invalidJsonResponse = await POST(
    new Request('http://localhost/api/assessments/unused/tools/runEngineeringScenario', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{',
    }),
    context('unused'),
  );
  assert.equal(invalidJsonResponse.status, 400);
  assert.deepEqual(await invalidJsonResponse.json(), { error: 'invalid_json' });

  const tamperedOutputResponse = await POST(
    new Request(`http://localhost/api/assessments/${fixture.assessmentId}/tools/runEngineeringScenario`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ output: { chargerCurrentAmps: 80 } }),
    }),
    context(fixture.assessmentId),
  );
  assert.equal(tamperedOutputResponse.status, 400);
  assert.equal((await tamperedOutputResponse.json()).error, 'validation_error');
});

test('POST /api/assessments/:id/tools/runEngineeringScenario returns 404 for a missing assessment', async () => {
  const response = await POST(
    new Request('http://localhost/api/assessments/missing/tools/runEngineeringScenario', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{}',
    }),
    context('missing'),
  );

  assert.equal(response.status, 404);
  assert.deepEqual(await response.json(), { error: 'assessment_not_found' });
});

test('POST /api/assessments/:id/tools/runEngineeringScenario persists an insufficient-data result', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(insufficientFixture),
  }));
  assert.equal(createResponse.status, 201);

  const response = await POST(
    new Request(`http://localhost/api/assessments/${insufficientFixture.assessmentId}/tools/runEngineeringScenario`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{}',
    }),
    context(insufficientFixture.assessmentId),
  );

  assert.equal(response.status, 200);
  const { assessment } = await response.json();
  assert.equal(assessment.finalAssessment.status, 'insufficient_data');
  assert.equal(assessment.engineeringScenarios.at(-1).status, 'insufficient_data');
});

test('POST /api/assessments/:id/tools/runEngineeringScenario replaces prior results on repeated calls', async () => {
  const createResponse = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(fixture),
  }));
  assert.equal(createResponse.status, 201);

  const request = () => new Request(`http://localhost/api/assessments/${fixture.assessmentId}/tools/runEngineeringScenario`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{}',
  });
  const firstResponse = await POST(request(), context(fixture.assessmentId));
  const secondResponse = await POST(request(), context(fixture.assessmentId));

  assert.equal(firstResponse.status, 200);
  assert.equal(secondResponse.status, 200);
  const { assessment } = await secondResponse.json();
  assert.equal(assessment.toolRuns.filter((toolRun: { id: string }) => toolRun.id === `tool-engineering-${fixture.assessmentId}`).length, 1);
  assert.equal(assessment.engineeringScenarios.filter((scenario: { id: string }) => scenario.id === `engineering-scenario-${fixture.assessmentId}`).length, 1);
});
