import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { decodeSiteGraph, SiteGraphSchema } from '../../../packages/schemas/src/sitegraph';
import { runEngineeringScenario, applyEngineeringScenario } from './engineering-calculator';

const TRUSTED_TIMESTAMP = '2030-01-02T03:04:05.000Z';
const DEFAULT_TRUSTED_TIMESTAMP = '1970-01-01T00:00:00.000Z';

function loadFixture(name: string) {
  const path = join(process.cwd(), 'packages/fixtures/sitegraph', `${name}.json`);
  return decodeSiteGraph(JSON.parse(readFileSync(path, 'utf8')));
}

test('recommends a low or medium current path for the modern 200 A fixture', () => {
  const result = runEngineeringScenario(loadFixture('modern-200a'));

  assert.equal(result.status, 'professional_verification_required');
  assert.ok(result.recommendation.chargerCurrentAmps === 32 || result.recommendation.chargerCurrentAmps === 48);
  assert.equal(result.recommendation.highCurrentRecommended, false);
  assert.equal(result.toolRun.toolName, 'runEngineeringScenario');
  assert.equal(result.toolRun.resultStatus, 'conditional');
  assert.match(result.disclaimer, /preliminary/i);
});

test('keeps the constrained 100 A fixture out of a high-current recommendation', () => {
  const result = runEngineeringScenario(loadFixture('constrained-100a'));

  assert.equal(result.status, 'professional_verification_required');
  assert.equal(result.recommendation.chargerCurrentAmps, 16);
  assert.equal(result.recommendation.highCurrentRecommended, false);
  assert.ok(result.professionalVerificationItems.length > 0);
  assert.equal(result.toolRun.resultStatus, 'conditional');
});

test('requires panel capacity evaluation instead of recommending a direct charger when no breaker spaces remain', () => {
  const modern = loadFixture('modern-200a');
  const result = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, spareBreakerSpaces: 0 },
  });

  assert.equal(result.status, 'professional_verification_required');
  assert.equal(result.recommendation.chargerCurrentAmps, null);
  assert.equal(result.recommendation.label, null);
  assert.ok(result.unresolvedRequirements.includes('Panel, subpanel, or service upgrade evaluation before any new dedicated EV circuit.'));
  assert.ok(result.professionalVerificationItems.includes('Licensed electrician evaluation of panel, subpanel, or service upgrade capacity before any new dedicated EV circuit.'));
  assert.ok(result.installerHandoff.bullets.some((bullet) => /panel, subpanel, or service upgrade evaluation/i.test(bullet)));
  assert.ok(result.installerHandoff.bullets.every((bullet) => !/dedicated circuit can fit/i.test(bullet)));
});

test('returns insufficient_data instead of inferring a recommendation with missing panel and route facts', () => {
  const result = runEngineeringScenario(loadFixture('insufficient-data'));

  assert.equal(result.status, 'insufficient_data');
  assert.equal(result.recommendation.chargerCurrentAmps, null);
  assert.equal(result.toolRun.resultStatus, 'insufficient_data');
  assert.deepEqual(result.missingInputs, [
    'usable panel service-amperage fact and evidence',
    'usable spare breaker-space fact and evidence',
    'usable feet-based route measurement',
  ]);
});

test('changes the derived handoff when a validated panel input changes', () => {
  const modern = loadFixture('modern-200a');
  const constrained = {
    ...modern,
    electricalPanel: { ...modern.electricalPanel, serviceAmps: 100, spareBreakerSpaces: 2 },
  };

  const modernResult = runEngineeringScenario(modern);
  const constrainedResult = runEngineeringScenario(constrained);

  assert.notDeepEqual(constrainedResult.recommendation, modernResult.recommendation);
  assert.notDeepEqual(constrainedResult.installerHandoff.bullets, modernResult.installerHandoff.bullets);
  assert.match(constrainedResult.installerHandoff.bullets.at(-1) ?? '', /16 A/);
});

test('returns insufficient_data when panel facts are contradicted despite populated values', () => {
  const modern = loadFixture('modern-200a');
  const result = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, status: 'contradicted' },
  });

  assert.equal(result.status, 'insufficient_data');
  assert.equal(result.recommendation.chargerCurrentAmps, null);
  assert.deepEqual(result.missingInputs, [
    'usable panel service-amperage fact and evidence',
    'usable spare breaker-space fact and evidence',
  ]);
  assert.deepEqual(result.installerHandoff.bullets, [
    'Capture usable panel service-amperage evidence.',
    'Capture usable spare breaker-space evidence.',
  ]);
});

test('requests only the individual unusable panel fact and evidence', () => {
  const modern = loadFixture('modern-200a');

  const missingService = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, serviceAmps: undefined },
  });
  const missingSpareSpaces = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, spareBreakerSpaces: undefined },
  });

  assert.deepEqual(missingService.missingInputs, ['usable panel service-amperage fact and evidence']);
  assert.deepEqual(missingService.installerHandoff.bullets, ['Capture usable panel service-amperage evidence.']);
  assert.deepEqual(missingSpareSpaces.missingInputs, ['usable spare breaker-space fact and evidence']);
  assert.deepEqual(missingSpareSpaces.installerHandoff.bullets, ['Capture usable spare breaker-space evidence.']);
});

test('returns insufficient_data for service amperage above the panel bus rating', () => {
  const modern = loadFixture('modern-200a');
  const result = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, serviceAmps: 226, busRatingAmps: 225 },
  });

  assert.equal(result.status, 'insufficient_data');
  assert.equal(result.recommendation.chargerCurrentAmps, null);
  assert.deepEqual(result.missingInputs, ['consistent panel service-amperage and bus-rating facts and evidence']);
  assert.deepEqual(result.installerHandoff.bullets, [
    'Capture evidence confirming consistent panel service-amperage and bus-rating facts.',
  ]);
});

test('selects the earliest usable positive feet route when other route facts are unusable', () => {
  const modern = loadFixture('modern-200a');
  const [route] = modern.measurements;
  const result = runEngineeringScenario({
    ...modern,
    evidence: [
      ...modern.evidence,
      { id: 'route-evidence-usable', type: 'measurement', label: 'Usable route measurement' },
    ],
    measurements: [
      { ...route, id: 'route-contradicted', value: 99, status: 'contradicted' },
      { ...route, id: 'route-meters', value: 5, unit: 'm' },
      { ...route, id: 'route-zero', value: 0 },
      { ...route, id: 'route-usable', value: 42, evidenceIds: ['route-evidence-usable'] },
    ],
  });

  assert.equal(result.status, 'professional_verification_required');
  assert.match(result.toolRun.inputSummary, /42 ft route/);
  assert.match(result.toolRun.inputSummary, /panel proposed\/visually_observed; route calculated\/measured/);
  assert.ok(result.toolRun.evidenceIds.includes('route-evidence-usable'));
});

test('rejects applying a result from a different assessment', () => {
  const constrainedResult = runEngineeringScenario(loadFixture('constrained-100a'));

  assert.throws(
    () => applyEngineeringScenario(loadFixture('modern-200a'), constrainedResult, DEFAULT_TRUSTED_TIMESTAMP),
    /result assessment origin does not match the input assessment/i,
  );
});

test('atomically applies a validated deterministic result with schema-permitted scenario status', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph, '2030-01-02T03:04:05.000Z');
  const applied = applyEngineeringScenario(graph, result, TRUSTED_TIMESTAMP);

  assert.equal(applied.toolRuns.at(-1)?.timestamp, '2030-01-02T03:04:05.000Z');
  assert.equal(applied.toolRuns.at(-1)?.resultStatus, 'conditional');
  assert.equal(applied.engineeringScenarios.at(-1)?.status, 'conditional');
  assert.equal(applied.finalAssessment.status, 'professional_verification_required');
  assert.equal(applied.finalAssessment.timestamp, '2030-01-02T03:04:05.000Z');
  assert.equal(graph.toolRuns.length, 1);
});

test('persists the typed calculation origin with the applied ToolRun output', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph, '2030-01-02T03:04:05.000Z');
  const applied = applyEngineeringScenario(graph, result, TRUSTED_TIMESTAMP);
  const storedToolRun = applied.toolRuns.find((toolRun) => toolRun.id === result.toolRun.id);

  assert.ok(storedToolRun);
  assert.deepEqual(storedToolRun.output.origin, result.origin);
  assert.deepEqual(SiteGraphSchema.parse(applied), applied);
});

test('reapplying the same deterministic result replaces its stable ToolRun', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph, '2030-01-02T03:04:05.000Z');
  const appliedOnce = applyEngineeringScenario(graph, result, TRUSTED_TIMESTAMP);
  const appliedTwice = applyEngineeringScenario(appliedOnce, result, TRUSTED_TIMESTAMP);

  assert.equal(
    appliedTwice.toolRuns.filter((toolRun) => toolRun.id === result.toolRun.id).length,
    1,
  );
  assert.deepEqual(appliedTwice, appliedOnce);
});

test('rejects schema-valid result tampering that does not change its origin snapshot', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph, '2030-01-02T03:04:05.000Z');
  const insufficientGraph = loadFixture('insufficient-data');
  const insufficientResult = runEngineeringScenario(insufficientGraph, '2030-01-02T03:04:05.000Z');
  const tamperedResults = [
    { ...result, status: 'pass' as const },
    { ...result, toolRun: { ...result.toolRun, resultStatus: 'pass' as const } },
    {
      ...result,
      recommendation: {
        ...result.recommendation,
        chargerCurrentAmps: 16,
      },
    },
    {
      ...result,
      recommendation: {
        ...result.recommendation,
        label: '16 A managed or low-current charger',
      },
    },
    {
      ...insufficientResult,
      toolRun: { ...insufficientResult.toolRun, output: { missingInputs: [] } },
    },
  ];

  for (const tamperedResult of tamperedResults) {
    const targetGraph = tamperedResult === tamperedResults.at(-1) ? insufficientGraph : graph;
    assert.throws(
      () => applyEngineeringScenario(targetGraph, tamperedResult, TRUSTED_TIMESTAMP),
      /result does not match the canonical deterministic calculation/i,
    );
  }
});

test('rejects a result when only the proposed EVSE wall changes', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph);
  const changedGraph = {
    ...graph,
    proposedEvseLocation: { ...graph.proposedEvseLocation, wall: 'east garage wall' },
  };

  assert.throws(
    () => applyEngineeringScenario(changedGraph, result, DEFAULT_TRUSTED_TIMESTAMP),
    /result inputs do not match the current calculation-relevant graph facts/i,
  );
});

test('pre-flight matrix handles zero, negative, and boundary panel capacity safely', () => {
  const modern = loadFixture('modern-200a');
  const zeroSpaces = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, spareBreakerSpaces: 0 },
  });
  const boundaryCapacity = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, serviceAmps: 100, spareBreakerSpaces: 1 },
  });

  assert.equal(zeroSpaces.recommendation.chargerCurrentAmps, null);
  assert.equal(zeroSpaces.toolRun.output.panelCapacityEvaluationRequired, true);
  assert.equal(boundaryCapacity.recommendation.chargerCurrentAmps, 16);
  assert.throws(
    () => runEngineeringScenario({
      ...modern,
      electricalPanel: { ...modern.electricalPanel, spareBreakerSpaces: -1 },
    }),
  );
});

test('pre-flight matrix rejects stale results after each output-affecting input changes independently', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph);
  const [route] = graph.measurements;
  const changedGraphs = [
    { ...graph, electricalPanel: { ...graph.electricalPanel, status: 'confirmed' as const } },
    { ...graph, electricalPanel: { ...graph.electricalPanel, sourceType: 'measured' as const } },
    { ...graph, electricalPanel: { ...graph.electricalPanel, evidenceIds: ['replacement-panel-evidence'] } },
    { ...graph, electricalPanel: { ...graph.electricalPanel, serviceAmps: 201 } },
    { ...graph, electricalPanel: { ...graph.electricalPanel, busRatingAmps: 226 } },
    { ...graph, electricalPanel: { ...graph.electricalPanel, breakerSpaceCount: 41 } },
    { ...graph, electricalPanel: { ...graph.electricalPanel, spareBreakerSpaces: 11 } },
    { ...graph, measurements: [{ ...route, id: 'replacement-route' }] },
    { ...graph, measurements: [{ ...route, value: 32 }] },
    { ...graph, measurements: [{ ...route, unit: 'feet' }] },
    { ...graph, measurements: [{ ...route, status: 'confirmed' as const }] },
    { ...graph, measurements: [{ ...route, sourceType: 'user_supplied' as const }] },
    { ...graph, measurements: [{ ...route, evidenceIds: ['replacement-route-evidence'] }] },
    { ...graph, proposedEvseLocation: { ...graph.proposedEvseLocation, wall: 'east garage wall' } },
  ];

  for (const changedGraph of changedGraphs) {
    assert.throws(
      () => applyEngineeringScenario(changedGraph, result, DEFAULT_TRUSTED_TIMESTAMP),
      /result inputs do not match the current calculation-relevant graph facts/i,
    );
  }
});

test('pre-flight matrix treats missing, implausibly low, contradicted, superseded, and evidence-free facts as unusable', () => {
  const modern = loadFixture('modern-200a');
  const [route] = modern.measurements;
  const inputs = [
    { ...modern, electricalPanel: { ...modern.electricalPanel, serviceAmps: undefined } },
    { ...modern, electricalPanel: { ...modern.electricalPanel, serviceAmps: 1 } },
    { ...modern, electricalPanel: { ...modern.electricalPanel, status: 'contradicted' as const } },
    { ...modern, electricalPanel: { ...modern.electricalPanel, status: 'superseded' as const } },
    { ...modern, electricalPanel: { ...modern.electricalPanel, evidenceIds: [] } },
    { ...modern, measurements: [{ ...route, status: 'contradicted' as const }] },
    { ...modern, measurements: [{ ...route, status: 'superseded' as const }] },
    { ...modern, measurements: [{ ...route, evidenceIds: [] }] },
  ];

  for (const input of inputs) {
    const result = runEngineeringScenario(input);
    assert.equal(result.status, 'insufficient_data');
    assert.equal(result.recommendation.chargerCurrentAmps, null);
  }
});

test('returns insufficient_data for an evidenced 1 A service with otherwise usable facts', () => {
  const modern = loadFixture('modern-200a');
  const result = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, serviceAmps: 1 },
  });

  assert.equal(result.status, 'insufficient_data');
  assert.deepEqual(result.recommendation, { chargerCurrentAmps: null, label: null, highCurrentRecommended: false });
  assert.deepEqual(result.missingInputs, ['plausible panel service-amperage fact and evidence (at least 60 A)']);
  assert.deepEqual(result.installerHandoff.bullets, ['Capture evidence confirming a plausible panel service-amperage rating of at least 60 A.']);
});

test('accepts a valid non-fixture evidence record for panel and route facts', () => {
  const modern = loadFixture('modern-200a');
  const result = runEngineeringScenario({
    ...modern,
    evidence: [{ id: 'captured-panel-route', type: 'measurement', label: 'Captured panel and route measurement' }],
    electricalPanel: { ...modern.electricalPanel, evidenceIds: ['captured-panel-route'] },
    measurements: [{ ...modern.measurements[0], evidenceIds: ['captured-panel-route'] }],
  });

  assert.equal(result.status, 'professional_verification_required');
  assert.equal(result.recommendation.chargerCurrentAmps, 32);
});

test('returns insufficient_data when panel or route evidence references do not resolve', () => {
  const modern = loadFixture('modern-200a');
  const unknownPanel = runEngineeringScenario({
    ...modern,
    electricalPanel: { ...modern.electricalPanel, evidenceIds: ['unknown-panel-evidence'] },
  });
  const replacedRoute = runEngineeringScenario({
    ...modern,
    measurements: [{ ...modern.measurements[0], evidenceIds: ['replaced-route-evidence'] }],
  });

  for (const result of [unknownPanel, replacedRoute]) {
    assert.equal(result.status, 'insufficient_data');
    assert.deepEqual(result.recommendation, { chargerCurrentAmps: null, label: null, highCurrentRecommended: false });
  }
});

test('rejects isolated and coordinated calculation timestamp tampering against the trusted invocation timestamp', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph, TRUSTED_TIMESTAMP);
  const tamperedTimestamp = '2030-01-02T03:04:06.000Z';
  const isolated = { ...result, toolRun: { ...result.toolRun, timestamp: tamperedTimestamp } };
  const coordinated = {
    ...result,
    origin: { ...result.origin, calculationTimestamp: tamperedTimestamp },
    toolRun: { ...result.toolRun, timestamp: tamperedTimestamp },
  };

  for (const tampered of [isolated, coordinated]) {
    assert.throws(
      () => applyEngineeringScenario(graph, tampered, TRUSTED_TIMESTAMP),
      /trusted calculation timestamp/i,
    );
  }
});

test('rejects a result when calculation-relevant panel facts change in the same assessment', () => {
  const graph = loadFixture('modern-200a');
  const result = runEngineeringScenario(graph);
  const changedGraph = {
    ...graph,
    electricalPanel: { ...graph.electricalPanel, serviceAmps: 100, spareBreakerSpaces: 2 },
  };

  assert.throws(
    () => applyEngineeringScenario(changedGraph, result, DEFAULT_TRUSTED_TIMESTAMP),
    /result inputs do not match the current calculation-relevant graph facts/i,
  );
});
