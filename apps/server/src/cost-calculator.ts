import { createHash } from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';
import { z } from 'zod';

import {
  AssessmentStatusSchema,
  CostScenarioSchema,
  SiteGraphSchema,
  SourceTypeSchema,
  ToolRunSchema,
  ValueStatusSchema,
  type SiteGraphV0,
} from '../../../packages/schemas/src/sitegraph';

const TOOL_VERSION = '0.1.0';
const DETERMINISTIC_CALCULATION_TIMESTAMP = '1970-01-01T00:00:00.000Z';
const COST_DISCLAIMER = 'This is a preliminary, fixture-scoped planning range, not an installer quote. Final scope, permits, code requirements, labor, equipment, and any panel/service work require licensed-electrician and AHJ confirmation.';
const AUSTIN_PERMIT_SOURCE = 'Austin Energy home-charging guidance (permit and inspection requirement): https://www.austinenergy.com/green-power/plug-in-austin/home-charging; City of Austin FY 2025-26 homeowner fee attachment (advisory $166.99 residential electric-fee anchor, not an EVSE permit quote): https://services.austintexas.gov/budget/cbq/index.cfm?action=pushFile&popup=true&FILE_ID=2050CEDEC9';
const AUSTIN_SOURCE_AHJ = 'City of Austin';
const ACCEPTABLE_STATUSES = new Set(['proposed', 'confirmed', 'professionally_verified', 'calculated']);
const ACCEPTABLE_SOURCE_TYPES = new Set(['measured', 'visually_observed', 'ocr_extracted', 'user_supplied', 'externally_retrieved', 'professionally_verified', 'calculated']);


const CostInputSnapshotSchema = z.object({
  jurisdiction: z.object({ city: z.string(), state: z.string(), ahj: z.string() }).strict(),
  panel: z.object({
    id: z.string(), status: ValueStatusSchema, sourceType: SourceTypeSchema, evidenceIds: z.array(z.string()),
    spareBreakerSpaces: z.number().int().nonnegative().optional(),
  }).strict(),
  route: z.object({
    id: z.string(), value: z.number(), unit: z.string(), status: ValueStatusSchema,
    sourceType: SourceTypeSchema, evidenceIds: z.array(z.string()),
  }).strict().nullable(),
}).strict();
type CostInputSnapshot = z.infer<typeof CostInputSnapshotSchema>;

const TotalSchema = z.object({ low: z.number().nonnegative(), expected: z.number().nonnegative(), high: z.number().nonnegative(), currency: z.literal('USD') }).strict()
  .refine((total) => total.low <= total.expected && total.expected <= total.high, 'Cost totals must be ordered.');

export const CostScenarioResultSchema = z.object({
  origin: z.object({ assessmentId: z.string(), inputSnapshot: CostInputSnapshotSchema, inputFingerprint: z.string().regex(/^[a-f0-9]{64}$/), calculationTimestamp: z.string().datetime({ offset: true }) }).strict(),
  status: AssessmentStatusSchema,
  costStatus: z.enum(['preliminary_range', 'partial_range', 'insufficient_data']),
  total: TotalSchema.nullable(),
  scenario: CostScenarioSchema.nullable(),
  missingInputs: z.array(z.string()),
  assumptions: z.array(z.string()),
  unresolvedRequirements: z.array(z.string()),
  professionalVerificationItems: z.array(z.string()),
  installerHandoff: z.object({ title: z.string(), bullets: z.array(z.string()) }).strict(),
  toolRun: ToolRunSchema,
  disclaimer: z.literal(COST_DISCLAIMER),
}).strict();
export type CostScenarioResult = z.infer<typeof CostScenarioResultSchema>;

function hasUsableEvidence(
  graph: SiteGraphV0,
  fact: { status: string; sourceType: string; evidenceIds: string[] },
): boolean {
  return ACCEPTABLE_STATUSES.has(fact.status) && ACCEPTABLE_SOURCE_TYPES.has(fact.sourceType)
    && fact.evidenceIds.length > 0
    && fact.evidenceIds.every((evidenceId) => graph.evidence.some((evidence) => evidence.id === evidenceId));
}

function selectUsableRoute(graph: SiteGraphV0) {
  return graph.measurements.find((measurement) => measurement.kind === 'route_length'
    && hasUsableEvidence(graph, measurement) && measurement.value > 0 && measurement.value <= 10000
    && (measurement.unit === 'ft' || measurement.unit === 'feet'));
}

function snapshotCostInputs(graph: SiteGraphV0, route = selectUsableRoute(graph)): CostInputSnapshot {
  return CostInputSnapshotSchema.parse({
    jurisdiction: { city: graph.site.jurisdiction.city, state: graph.site.jurisdiction.state, ahj: graph.site.jurisdiction.ahj },
    panel: { id: graph.electricalPanel.id, status: graph.electricalPanel.status, sourceType: graph.electricalPanel.sourceType, evidenceIds: graph.electricalPanel.evidenceIds, spareBreakerSpaces: graph.electricalPanel.spareBreakerSpaces },
    route: route === undefined ? null : { id: route.id, value: route.value, unit: route.unit, status: route.status, sourceType: route.sourceType, evidenceIds: route.evidenceIds },
  });
}
function fingerprintCostInputs(snapshot: CostInputSnapshot): string {
  return createHash('sha256').update(JSON.stringify(snapshot)).digest('hex');
}
function isAustinDemoJurisdiction(graph: SiteGraphV0): boolean {
  return graph.site.jurisdiction.city.trim().toLowerCase() === 'austin'
    && graph.site.jurisdiction.state.trim().toUpperCase() === 'TX'
    && graph.site.jurisdiction.ahj === AUSTIN_SOURCE_AHJ;
}
function roundCurrency(value: number): number { return Math.round(value * 100) / 100; }
function totalFor(lineItems: Array<{ low: number; expected: number; high: number }>) {
  return { low: roundCurrency(lineItems.reduce((sum, item) => sum + item.low, 0)), expected: roundCurrency(lineItems.reduce((sum, item) => sum + item.expected, 0)), high: roundCurrency(lineItems.reduce((sum, item) => sum + item.high, 0)), currency: 'USD' as const };
}

export function runCostScenario(input: unknown, calculationTimestamp = DETERMINISTIC_CALCULATION_TIMESTAMP): CostScenarioResult {
  const graph = SiteGraphSchema.parse(input);
  const timestamp = z.string().datetime({ offset: true }).parse(calculationTimestamp);
  const route = selectUsableRoute(graph);
  const panel = graph.electricalPanel;
  const panelUsable = hasUsableEvidence(graph, panel) && panel.spareBreakerSpaces !== undefined
    && (panel.breakerSpaceCount === undefined || panel.spareBreakerSpaces <= panel.breakerSpaceCount);
  const snapshot = snapshotCostInputs(graph, route);
  const origin = { assessmentId: graph.assessmentId, inputSnapshot: snapshot, inputFingerprint: fingerprintCostInputs(snapshot), calculationTimestamp: timestamp };
  const missingInputs = [
    ...(!isAustinDemoJurisdiction(graph) ? ['Austin, TX demo jurisdiction evidence for the permit-fee anchor'] : []),
    ...(!panelUsable ? ['usable spare breaker-space fact and evidence'] : []),
    ...(route === undefined ? ['usable positive feet-based route measurement'] : []),
  ];
  const evidenceIds = [...(panelUsable ? panel.evidenceIds : []), ...(route?.evidenceIds ?? [])];
  if (missingInputs.length > 0) {
    return CostScenarioResultSchema.parse({
      origin, status: 'insufficient_data', costStatus: 'insufficient_data', total: null, scenario: null, missingInputs,
      assumptions: [], unresolvedRequirements: missingInputs,
      professionalVerificationItems: ['Licensed electrician review after required site facts are collected.'],
      installerHandoff: { title: 'Cost range waiting for required site observations', bullets: missingInputs.map((item) => item.includes('route') ? 'Record a usable positive feet-based route measurement.' : item.includes('spare') ? 'Capture usable spare breaker-space evidence.' : 'Use a jurisdiction-specific permit-fee source before estimating permits.') },
      toolRun: { id: `tool-cost-${graph.assessmentId}`, toolName: 'runCostScenario', version: TOOL_VERSION, inputSummary: 'Missing route, panel-space, or applicable jurisdiction facts', resultStatus: 'insufficient_data', warnings: ['No cost range is calculated when route, panel-space, or jurisdiction evidence is unusable.'], assumptions: [], evidenceIds, output: { missingInputs }, timestamp },
      disclaimer: COST_DISCLAIMER,
    });
  }

  // All non-government price numbers below are intentionally demo-fixture assumptions, not market research or quotes.
  const routeForCost = route!;
  const routeFeet = routeForCost.value;
  const lineItems = [
    { id: 'fixture-evse', label: 'EVSE hardware planning allowance', quantity: 1, unit: 'unit', low: 400, expected: 600, high: 900, currency: 'USD' as const, source: 'Fixture-scoped demo assumption; not a vendor quote.', assumptions: ['Consumer wall-mounted EVSE; exact equipment intentionally unselected.'] },
    { id: 'fixture-route-install', label: 'Route-dependent installation planning allowance', quantity: routeFeet, unit: 'ft', low: roundCurrency(routeFeet * 16), expected: roundCurrency(routeFeet * 25), high: roundCurrency(routeFeet * 40), currency: 'USD' as const, source: 'Fixture-scoped demo assumption; not a contractor labor/material quote.', assumptions: ['Route length is a planning proxy only; concealment, trenching, drywall, conductor size, and access are not priced.'] },
    { id: 'austin-residential-electric-fee-anchor', label: 'Residential electrical permit-fee planning anchor', quantity: 1, unit: 'allowance', low: 166.99, expected: 166.99, high: 166.99, currency: 'USD' as const, source: AUSTIN_PERMIT_SOURCE, assumptions: ['Advisory Austin homeowner-table anchor only, not an EVSE permit quote; fee and scope must be confirmed with the AHJ.'] },
  ];
  const total = totalFor(lineItems);
  const noSpareSpace = panel.spareBreakerSpaces === 0;
  const costStatus = noSpareSpace ? 'partial_range' as const : 'preliminary_range' as const;
  const status = 'professional_verification_required' as const;
  const upgradeRequirement = 'Panel, subpanel, or service-upgrade scope and cost are unknown and excluded from this range pending licensed-electrician evaluation.';
  const assumptions = [
    'This range is a fixture-scoped planning assumption, not a quote, bid, invoice, or guaranteed price.',
    'Austin permit and inspection are required for hard-wired home charging stations and receptacles for plug-in stations; confirm the actual permit scope and fee with the AHJ.',
    ...(noSpareSpace ? ['No panel/service upgrade allowance is included because the required upgrade scope is not established.'] : ['No panel, subpanel, or service upgrade is included; electrician review can change scope and cost.']),
  ];
  const scenario = { id: `cost-scenario-${graph.assessmentId}`, label: noSpareSpace ? 'Partial EVSE planning range — upgrade excluded' : 'Preliminary EVSE planning range', status: 'conditional' as const, totalLow: total.low, totalExpected: total.expected, totalHigh: total.high, currency: 'USD' as const, lineItems, assumptions, warnings: [COST_DISCLAIMER, ...(noSpareSpace ? [upgradeRequirement] : [])], evidenceIds };
  return CostScenarioResultSchema.parse({
    origin, status, costStatus, total, scenario, missingInputs: [], assumptions,
    unresolvedRequirements: ['Licensed electrician scope review', 'AHJ permit fee and inspection confirmation', ...(noSpareSpace ? [upgradeRequirement] : [])],
    professionalVerificationItems: ['Licensed electrician review of conductor, breaker, routing, and panel capacity.', 'AHJ permit/inspection confirmation.'],
    installerHandoff: { title: noSpareSpace ? 'Partial cost handoff — panel capacity scope unpriced' : 'Preliminary cost handoff', bullets: [`Observed route used for planning: ${routeFeet} ${routeForCost.unit}.`, 'Range is fixture-scoped and not an installer quote.', 'Confirm permit scope and fee with City of Austin.', ...(noSpareSpace ? ['No spare breaker spaces observed: obtain panel, subpanel, or service-upgrade evaluation and separate pricing before relying on any project total.'] : ['Confirm panel capacity and final route before pricing.'])] },
    toolRun: { id: `tool-cost-${graph.assessmentId}`, toolName: 'runCostScenario', version: TOOL_VERSION, inputSummary: `Austin, TX demo jurisdiction; ${routeFeet} ${routeForCost.unit} usable route; ${panel.spareBreakerSpaces} evidenced spare spaces`, resultStatus: 'conditional', warnings: [COST_DISCLAIMER, ...(noSpareSpace ? [upgradeRequirement] : [])], assumptions, evidenceIds, output: { costStatus, total, panelUpgradeExcluded: noSpareSpace, permitAnchor: '166.99 USD advisory homeowner-table anchor, not quote' }, timestamp },
    disclaimer: COST_DISCLAIMER,
  });
}

/** Pure, typed adapter; it records a canonical cost ToolRun and replaces only this calculator's stable scenario. */
export function applyCostScenario(
  input: SiteGraphV0,
  resultInput: CostScenarioResult,
  expectedCalculationTimestamp?: string,
): SiteGraphV0 {
  const graph = SiteGraphSchema.parse(input);
  const result = CostScenarioResultSchema.parse(resultInput);
  const trustedTimestamp = expectedCalculationTimestamp === undefined
    ? result.origin.calculationTimestamp
    : z.string().datetime({ offset: true }).parse(expectedCalculationTimestamp);
  if (result.origin.assessmentId !== graph.assessmentId) throw new Error('Result assessment origin does not match the input assessment.');
  if (result.origin.calculationTimestamp !== trustedTimestamp || result.toolRun.timestamp !== trustedTimestamp) throw new Error('Result does not match the trusted calculation timestamp.');
  const currentSnapshot = snapshotCostInputs(graph);
  const currentFingerprint = fingerprintCostInputs(currentSnapshot);
  if (result.origin.inputFingerprint !== fingerprintCostInputs(result.origin.inputSnapshot) || result.origin.inputFingerprint !== currentFingerprint || !isDeepStrictEqual(result.origin.inputSnapshot, currentSnapshot)) throw new Error('Result inputs do not match the current calculation-relevant graph facts.');
  const canonical = runCostScenario(graph, trustedTimestamp);
  if (!isDeepStrictEqual(result, canonical)) throw new Error('Result does not match the canonical deterministic calculation.');
  const toolRun = ToolRunSchema.parse({ ...result.toolRun, output: { ...result.toolRun.output, origin: result.origin } });
  const scenarioId = `cost-scenario-${graph.assessmentId}`;
  return SiteGraphSchema.parse({ ...graph, toolRuns: [...graph.toolRuns.filter((existing) => existing.id !== toolRun.id), toolRun], costScenarios: result.scenario === null ? graph.costScenarios.filter((existing) => existing.id !== scenarioId) : [...graph.costScenarios.filter((existing) => existing.id !== scenarioId), result.scenario] });
}
