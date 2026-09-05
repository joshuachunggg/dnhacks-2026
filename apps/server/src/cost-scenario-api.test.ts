import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { POST } from '../../../src/app/api/assessments/[assessmentId]/tools/runCostScenario/route';

const fixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/modern-200a.json');
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'));
const insufficientFixturePath = join(process.cwd(), 'packages/fixtures/sitegraph/insufficient-data.json');
const insufficientFixture = JSON.parse(readFileSync(insufficientFixturePath, 'utf8'));

function context(assessmentId: string) {
  return { params: Promise.resolve({ assessmentId }) };
}

async function create(input: unknown) {
  const response = await createAssessment(new Request('http://localhost/api/assessments', {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(input),
  }));
  assert.equal(response.status, 201);
}

function request(assessmentId: string, body = '{}') {
  return new Request(`http://localhost/api/assessments/${assessmentId}/tools/runCostScenario`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body,
  });
}

test('POST /api/assessments/:id/tools/runCostScenario calculates and persists the canonical cost scenario', async () => {
  const modernFixture = { ...fixture, assessmentId: 'cost-api-modern-success' };
  await create(modernFixture);

  const response = await POST(request(modernFixture.assessmentId), context(modernFixture.assessmentId));

  assert.equal(response.status, 200);
  const { assessment } = await response.json();
  const toolRun = assessment.toolRuns.at(-1);
  assert.equal(toolRun.toolName, 'runCostScenario');
  assert.equal(assessment.costScenarios.at(-1).totalExpected, 1541.99);
  assert.match(toolRun.timestamp, /^\d{4}-\d{2}-\d{2}T/);
  assert.equal(toolRun.output.origin.calculationTimestamp, toolRun.timestamp);
});

test('POST /api/assessments/:id/tools/runCostScenario persists an insufficient-data result', async () => {
  const missingFactsFixture = { ...insufficientFixture, assessmentId: 'cost-api-insufficient' };
  await create(missingFactsFixture);

  const response = await POST(request(missingFactsFixture.assessmentId), context(missingFactsFixture.assessmentId));

  assert.equal(response.status, 200);
  const { assessment } = await response.json();
  assert.equal(assessment.finalAssessment.status, 'insufficient_data');
  assert.equal(assessment.toolRuns.at(-1).resultStatus, 'insufficient_data');
  assert.equal(assessment.costScenarios.some((scenario: { id: string }) => scenario.id === `cost-scenario-${missingFactsFixture.assessmentId}`), false);
});

test('POST /api/assessments/:id/tools/runCostScenario rejects invalid JSON and tampered bodies', async () => {
  const invalidJsonResponse = await POST(request('unused', '{'), context('unused'));
  assert.equal(invalidJsonResponse.status, 400);
  assert.deepEqual(await invalidJsonResponse.json(), { error: 'invalid_json' });

  const modernFixture = { ...fixture, assessmentId: 'cost-api-tampered-body' };
  await create(modernFixture);
  const tamperedResponse = await POST(request(modernFixture.assessmentId, JSON.stringify({ total: { expected: 1 } })), context(modernFixture.assessmentId));
  assert.equal(tamperedResponse.status, 400);
  assert.equal((await tamperedResponse.json()).error, 'validation_error');
});

test('POST /api/assessments/:id/tools/runCostScenario returns 404 for a missing assessment', async () => {
  const response = await POST(request('missing'), context('missing'));

  assert.equal(response.status, 404);
  assert.deepEqual(await response.json(), { error: 'assessment_not_found' });
});

test('POST /api/assessments/:id/tools/runCostScenario replaces prior results on repeated calls', async () => {
  const modernFixture = { ...fixture, assessmentId: 'cost-api-repeat' };
  await create(modernFixture);

  assert.equal((await POST(request(modernFixture.assessmentId), context(modernFixture.assessmentId))).status, 200);
  const secondResponse = await POST(request(modernFixture.assessmentId), context(modernFixture.assessmentId));

  assert.equal(secondResponse.status, 200);
  const { assessment } = await secondResponse.json();
  assert.equal(assessment.toolRuns.filter((toolRun: { id: string }) => toolRun.id === `tool-cost-${modernFixture.assessmentId}`).length, 1);
  assert.equal(assessment.costScenarios.filter((scenario: { id: string }) => scenario.id === `cost-scenario-${modernFixture.assessmentId}`).length, 1);
});

test('POST /api/assessments/:id/tools/runCostScenario stores a partial range without representing it as a complete project price when no spare space exists', async () => {
  const noSpareFixture = {
    ...fixture,
    assessmentId: 'cost-api-no-spare-space',
    electricalPanel: { ...fixture.electricalPanel, spareBreakerSpaces: 0 },
  };
  await create(noSpareFixture);

  const response = await POST(request(noSpareFixture.assessmentId), context(noSpareFixture.assessmentId));

  assert.equal(response.status, 200);
  const { assessment } = await response.json();
  const toolRun = assessment.toolRuns.at(-1);
  const scenario = assessment.costScenarios.at(-1);
  assert.equal(toolRun.output.costStatus, 'partial_range');
  assert.equal(toolRun.output.panelUpgradeExcluded, true);
  assert.match(scenario.label, /^Partial EVSE planning range/);
  assert.equal(scenario.warnings.some((warning: string) => warning.includes('excluded from this range')), true);
  assert.equal(scenario.label.includes('complete project'), false);
});
