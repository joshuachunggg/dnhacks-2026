import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { decodeSiteGraph } from '../../../packages/schemas/src/sitegraph';
import { applyCostScenario, CostScenarioResultSchema, runCostScenario } from './cost-calculator';

const TRUSTED_TIMESTAMP = '2030-01-02T03:04:05.000Z';

function loadFixture(name: string) {
  const path = join(process.cwd(), 'packages/fixtures/sitegraph', `${name}.json`);
  return decodeSiteGraph(JSON.parse(readFileSync(path, 'utf8')));
}

test('returns a deterministic, fixture-scoped preliminary range for the modern Austin fixture', () => {
  const result = runCostScenario(loadFixture('modern-200a'));

  assert.equal(result.status, 'professional_verification_required');
  assert.equal(result.costStatus, 'preliminary_range');
  assert.deepEqual(result.total, { low: 1062.99, expected: 1541.99, high: 2306.99, currency: 'USD' });
  assert.equal(result.scenario!.status, 'conditional');
  assert.ok(result.scenario!.lineItems.every((lineItem) => /fixture-scoped|Austin/i.test(lineItem.source)));
  assert.ok(result.assumptions.some((assumption) => /not a quote/i.test(assumption)));
  assert.ok(result.unresolvedRequirements.some((requirement) => /permit/i.test(requirement)));
  assert.equal(result.toolRun.toolName, 'runCostScenario');
  assert.equal(result.toolRun.resultStatus, 'conditional');
});

test('uses the evidenced route in range math and changes the range when that route changes', () => {
  const graph = loadFixture('constrained-100a');
  const original = runCostScenario(graph);
  const changed = runCostScenario({ ...graph, measurements: [{ ...graph.measurements[0], value: 80 }] });

  assert.equal(original.total?.expected, 2116.99);
  assert.equal(changed.total?.expected, 2766.99);
  assert.notDeepEqual(original.total, changed.total);
  assert.equal(changed.scenario?.lineItems.find((lineItem) => lineItem.id === 'fixture-route-install')?.quantity, 80);
});

test('returns no numeric range when route or panel-space evidence is unusable', () => {
  const insufficient = runCostScenario(loadFixture('insufficient-data'));
  const modern = loadFixture('modern-200a');
  const contradictedRoute = runCostScenario({ ...modern, measurements: [{ ...modern.measurements[0], status: 'contradicted' }] });

  for (const result of [insufficient, contradictedRoute]) {
    assert.equal(result.status, 'insufficient_data');
    assert.equal(result.costStatus, 'insufficient_data');
    assert.equal(result.total, null);
    assert.equal(result.scenario, null);
    assert.equal(result.toolRun.resultStatus, 'insufficient_data');
  }
});

test('returns no numeric range when a panel or route evidence ID does not resolve in graph evidence', () => {
  const modern = loadFixture('modern-200a');
  const unknownPanelEvidence = runCostScenario({ ...modern, electricalPanel: { ...modern.electricalPanel, evidenceIds: ['replaced-panel-evidence'] } });
  const unknownRouteEvidence = runCostScenario({ ...modern, measurements: [{ ...modern.measurements[0], evidenceIds: ['replaced-route-evidence'] }] });

  for (const result of [unknownPanelEvidence, unknownRouteEvidence]) {
    assert.equal(result.status, 'insufficient_data');
    assert.equal(result.costStatus, 'insufficient_data');
    assert.equal(result.total, null);
    assert.equal(result.scenario, null);
  }
});

test('accepts a valid non-fixture evidence record for priced panel and route facts', () => {
  const modern = loadFixture('modern-200a');
  const result = runCostScenario({
    ...modern,
    evidence: [{ id: 'captured-price-input', type: 'measurement', label: 'Captured panel and route measurement' }],
    electricalPanel: { ...modern.electricalPanel, evidenceIds: ['captured-price-input'] },
    measurements: [{ ...modern.measurements[0], evidenceIds: ['captured-price-input'] }],
  });

  assert.equal(result.status, 'professional_verification_required');
  assert.ok(result.total);
});

test('returns no numeric range or Austin fee anchor for an incompatible Austin-area AHJ', () => {
  const modern = loadFixture('modern-200a');
  const result = runCostScenario({ ...modern, site: { ...modern.site, jurisdiction: { ...modern.site.jurisdiction, ahj: 'Travis County' } } });

  assert.equal(result.status, 'insufficient_data');
  assert.equal(result.costStatus, 'insufficient_data');
  assert.equal(result.total, null);
  assert.equal(result.scenario, null);
  assert.ok(!result.toolRun.evidenceIds.some((evidenceId) => /austin/i.test(evidenceId)));
  assert.ok(!JSON.stringify(result).includes('austin-residential-electric-fee-anchor'));
});

test('makes panel upgrade uncertainty explicit without presenting a complete-project quote', () => {
  const modern = loadFixture('modern-200a');
  const result = runCostScenario({ ...modern, electricalPanel: { ...modern.electricalPanel, spareBreakerSpaces: 0 } });

  assert.equal(result.costStatus, 'partial_range');
  assert.ok(result.total);
  assert.ok(result.assumptions.some((assumption) => /upgrade allowance is included/i.test(assumption)));
  assert.ok(result.unresolvedRequirements.some((requirement) => /upgrade scope and cost are unknown/i.test(requirement)));
  assert.ok(result.installerHandoff.bullets.some((bullet) => /separate pricing/i.test(bullet)));
  assert.ok(result.scenario?.warnings.some((warning) => /upgrade scope and cost are unknown/i.test(warning)));
});

test('returns a Zod-validated result with line-item totals that equal the declared range', () => {
  const result = runCostScenario(loadFixture('modern-200a'));
  const scenario = result.scenario;
  assert.ok(scenario);
  assert.deepEqual(CostScenarioResultSchema.parse(result), result);
  const sum = (key: 'low' | 'expected' | 'high') => scenario.lineItems.reduce((total, item) => total + item[key], 0);
  assert.equal(result.total?.low, sum('low'));
  assert.equal(result.total?.expected, sum('expected'));
  assert.equal(result.total?.high, sum('high'));
});

test('adapter rejects stale, tampered, and wrong-assessment results and is idempotent for a canonical result', () => {
  const graph = loadFixture('modern-200a');
  const result = runCostScenario(graph, '2030-01-02T03:04:05.000Z');
  const appliedOnce = applyCostScenario(graph, result, TRUSTED_TIMESTAMP);
  const appliedTwice = applyCostScenario(appliedOnce, result, TRUSTED_TIMESTAMP);

  assert.equal(appliedOnce.costScenarios.filter((scenario) => scenario.id === 'cost-scenario-assessment-modern-200a').length, 1);
  assert.deepEqual(appliedTwice, appliedOnce);
  assert.deepEqual(appliedOnce.toolRuns.find((toolRun) => toolRun.id === result.toolRun.id)?.output.origin, result.origin);
  assert.throws(() => applyCostScenario({ ...graph, measurements: [{ ...graph.measurements[0], value: 44 }] }, result, TRUSTED_TIMESTAMP), /inputs do not match/i);
  assert.throws(() => applyCostScenario(graph, { ...result, total: { ...result.total!, expected: 1600 } }, TRUSTED_TIMESTAMP), /canonical deterministic calculation/i);
  assert.throws(() => applyCostScenario(loadFixture('constrained-100a'), result, TRUSTED_TIMESTAMP), /assessment origin/i);
});

test('adapter rejects a result whose canonical calculation timestamp was changed', () => {
  const graph = loadFixture('modern-200a');
  const result = runCostScenario(graph, '2030-01-02T03:04:05.000Z');
  const timestampTampered = { ...result, toolRun: { ...result.toolRun, timestamp: '2030-01-02T03:04:06.000Z' } };

  assert.throws(() => applyCostScenario(graph, timestampTampered, TRUSTED_TIMESTAMP), /trusted calculation timestamp/i);
});

test('adapter rejects isolated and coordinated timestamp tampering against the trusted invocation timestamp', () => {
  const graph = loadFixture('modern-200a');
  const result = runCostScenario(graph, TRUSTED_TIMESTAMP);
  const tamperedTimestamp = '2030-01-02T03:04:06.000Z';
  const isolated = { ...result, toolRun: { ...result.toolRun, timestamp: tamperedTimestamp } };
  const coordinated = {
    ...result,
    origin: { ...result.origin, calculationTimestamp: tamperedTimestamp },
    toolRun: { ...result.toolRun, timestamp: tamperedTimestamp },
  };

  for (const tampered of [isolated, coordinated]) {
    assert.throws(
      () => applyCostScenario(graph, tampered, TRUSTED_TIMESTAMP),
      /trusted calculation timestamp/i,
    );
  }
});
