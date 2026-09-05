import { createHash } from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';
import { z } from 'zod';

import {
  AssessmentStatusSchema,
  SiteGraphSchema,
  SourceTypeSchema,
  ToolRunSchema,
  ValueStatusSchema,
  type SiteGraphV0,
} from '../../../packages/schemas/src/sitegraph';

const TOOL_VERSION = '0.1.0';
const DETERMINISTIC_CALCULATION_TIMESTAMP = '1970-01-01T00:00:00.000Z';
const SAFETY_DISCLAIMER = 'This assessment is preliminary and based on visible evidence, user input, and deterministic checks. Final electrical decisions require a licensed electrician or the authority having jurisdiction.';
const ACCEPTABLE_STATUSES = new Set(['proposed', 'confirmed', 'professionally_verified', 'calculated']);
const ACCEPTABLE_SOURCE_TYPES = new Set(['measured', 'visually_observed', 'ocr_extracted', 'user_supplied', 'externally_retrieved', 'professionally_verified', 'calculated']);
const MINIMUM_PLAUSIBLE_SERVICE_AMPS = 60;

const EngineeringInputSnapshotSchema = z.object({
  panel: z.object({
    id: z.string(),
    status: ValueStatusSchema,
    sourceType: SourceTypeSchema,
    evidenceIds: z.array(z.string()),
    serviceAmps: z.number().int().positive().optional(),
    busRatingAmps: z.number().int().positive().optional(),
    breakerSpaceCount: z.number().int().nonnegative().optional(),
    spareBreakerSpaces: z.number().int().nonnegative().optional(),
  }).strict(),
  route: z.object({
    id: z.string(),
    value: z.number(),
    unit: z.string(),
    status: ValueStatusSchema,
    sourceType: SourceTypeSchema,
    evidenceIds: z.array(z.string()),
  }).strict().nullable(),
  proposedEvseLocation: z.object({
    wall: z.string(),
  }).strict(),
}).strict();

type EngineeringInputSnapshot = z.infer<typeof EngineeringInputSnapshotSchema>;

function hasUsableEvidence(
  graph: SiteGraphV0,
  fact: { status: string; sourceType: string; evidenceIds: string[] },
): boolean {
  return ACCEPTABLE_STATUSES.has(fact.status)
    && ACCEPTABLE_SOURCE_TYPES.has(fact.sourceType)
    && fact.evidenceIds.length > 0
    && fact.evidenceIds.every((evidenceId) => graph.evidence.some((evidence) => evidence.id === evidenceId));
}

function selectUsableRoute(graph: SiteGraphV0) {
  return graph.measurements.find((measurement) => measurement.kind === 'route_length'
    && hasUsableEvidence(graph, measurement)
    && measurement.value > 0
    && measurement.value <= 10000
    && (measurement.unit === 'ft' || measurement.unit === 'feet'));
}

function snapshotEngineeringInputs(
  graph: SiteGraphV0,
  route = selectUsableRoute(graph),
): EngineeringInputSnapshot {
  const panel = graph.electricalPanel;
  return EngineeringInputSnapshotSchema.parse({
    panel: {
      id: panel.id,
      status: panel.status,
      sourceType: panel.sourceType,
      evidenceIds: panel.evidenceIds,
      serviceAmps: panel.serviceAmps,
      busRatingAmps: panel.busRatingAmps,
      breakerSpaceCount: panel.breakerSpaceCount,
      spareBreakerSpaces: panel.spareBreakerSpaces,
    },
    route: route === undefined ? null : {
      id: route.id,
      value: route.value,
      unit: route.unit,
      status: route.status,
      sourceType: route.sourceType,
      evidenceIds: route.evidenceIds,
    },
    proposedEvseLocation: {
      wall: graph.proposedEvseLocation.wall,
    },
  });
}

function fingerprintEngineeringInputs(snapshot: EngineeringInputSnapshot): string {
  return createHash('sha256').update(JSON.stringify(snapshot)).digest('hex');
}

export const EngineeringScenarioResultSchema = z.object({
  origin: z.object({
    assessmentId: z.string(),
    inputSnapshot: EngineeringInputSnapshotSchema,
    inputFingerprint: z.string().regex(/^[a-f0-9]{64}$/),
    calculationTimestamp: z.string().datetime({ offset: true }),
  }).strict(),
  status: AssessmentStatusSchema,
  recommendation: z.object({
    chargerCurrentAmps: z.number().int().positive().nullable(),
    label: z.string().nullable(),
    highCurrentRecommended: z.boolean(),
  }).strict(),
  missingInputs: z.array(z.string()),
  unresolvedRequirements: z.array(z.string()),
  professionalVerificationItems: z.array(z.string()),
  installerHandoff: z.object({ title: z.string(), bullets: z.array(z.string()) }).strict(),
  toolRun: ToolRunSchema,
  disclaimer: z.literal(SAFETY_DISCLAIMER),
}).strict();

export type EngineeringScenarioResult = z.infer<typeof EngineeringScenarioResultSchema>;

export function runEngineeringScenario(
  input: unknown,
  calculationTimestamp = DETERMINISTIC_CALCULATION_TIMESTAMP,
): EngineeringScenarioResult {
  const graph = SiteGraphSchema.parse(input);
  const timestamp = z.string().datetime({ offset: true }).parse(calculationTimestamp);
  const panel = graph.electricalPanel;
  const serviceAmps = panel.serviceAmps;
  const spareBreakerSpaces = panel.spareBreakerSpaces;
  const panelEvidenceUsable = hasUsableEvidence(graph, panel);
  const serviceAmpsUsable = panelEvidenceUsable
    && serviceAmps !== undefined
    && serviceAmps >= MINIMUM_PLAUSIBLE_SERVICE_AMPS
    && serviceAmps <= 1000;
  const spareBreakerSpacesUsable = panelEvidenceUsable
    && spareBreakerSpaces !== undefined
    && (panel.breakerSpaceCount === undefined || spareBreakerSpaces <= panel.breakerSpaceCount);
  const panelRatingsConsistent = panel.busRatingAmps === undefined
    || serviceAmps === undefined
    || serviceAmps <= panel.busRatingAmps;
  const panelUsable = serviceAmpsUsable && spareBreakerSpacesUsable && panelRatingsConsistent;
  const route = selectUsableRoute(graph);
  const inputSnapshot = snapshotEngineeringInputs(graph, route);
  const origin = {
    assessmentId: graph.assessmentId,
    inputSnapshot,
    inputFingerprint: fingerprintEngineeringInputs(inputSnapshot),
    calculationTimestamp: timestamp,
  };
  const missingInputs = [
    ...(!panelRatingsConsistent
      ? ['consistent panel service-amperage and bus-rating facts and evidence']
      : [
        ...(!serviceAmpsUsable
          ? [serviceAmps !== undefined && serviceAmps < MINIMUM_PLAUSIBLE_SERVICE_AMPS
            ? `plausible panel service-amperage fact and evidence (at least ${MINIMUM_PLAUSIBLE_SERVICE_AMPS} A)`
            : 'usable panel service-amperage fact and evidence']
          : []),
        ...(!spareBreakerSpacesUsable ? ['usable spare breaker-space fact and evidence'] : []),
      ]),
    ...(route === undefined ? ['usable feet-based route measurement'] : []),
  ];
  const evidenceIds = [
    ...(panelUsable ? panel.evidenceIds : []),
    ...(route?.evidenceIds ?? []),
  ];

  if (!panelUsable || route === undefined) {
    return EngineeringScenarioResultSchema.parse({
      origin,
      status: 'insufficient_data',
      recommendation: { chargerCurrentAmps: null, label: null, highCurrentRecommended: false },
      missingInputs,
      unresolvedRequirements: missingInputs,
      professionalVerificationItems: ['Licensed electrician review after required site facts are collected.'],
      installerHandoff: {
        title: 'Waiting for required site observations',
        bullets: missingInputs.map((missingInput) => {
          if (missingInput === 'consistent panel service-amperage and bus-rating facts and evidence') {
            return 'Capture evidence confirming consistent panel service-amperage and bus-rating facts.';
          }
          if (missingInput === 'usable panel service-amperage fact and evidence') {
            return 'Capture usable panel service-amperage evidence.';
          }
          if (missingInput === `plausible panel service-amperage fact and evidence (at least ${MINIMUM_PLAUSIBLE_SERVICE_AMPS} A)`) {
            return `Capture evidence confirming a plausible panel service-amperage rating of at least ${MINIMUM_PLAUSIBLE_SERVICE_AMPS} A.`;
          }
          if (missingInput === 'usable spare breaker-space fact and evidence') {
            return 'Capture usable spare breaker-space evidence.';
          }
          return 'Record a usable positive feet-based route measurement.';
        }),
      },
      toolRun: {
        id: `tool-engineering-${graph.assessmentId}`,
        toolName: 'runEngineeringScenario',
        version: TOOL_VERSION,
        inputSummary: 'Missing panel or route facts',
        resultStatus: 'insufficient_data',
        warnings: ['The deterministic screen does not infer missing panel or route facts.'],
        assumptions: [],
        evidenceIds,
        output: { missingInputs },
        timestamp,
      },
      disclaimer: SAFETY_DISCLAIMER,
    });
  }

  if (spareBreakerSpaces === 0) {
    const capacityRequirement = 'Panel, subpanel, or service upgrade evaluation before any new dedicated EV circuit.';
    return EngineeringScenarioResultSchema.parse({
      origin,
      status: 'professional_verification_required',
      recommendation: { chargerCurrentAmps: null, label: null, highCurrentRecommended: false },
      missingInputs: [],
      unresolvedRequirements: [capacityRequirement, 'True load calculation', 'Final electrician review'],
      professionalVerificationItems: [
        'Licensed electrician evaluation of panel, subpanel, or service upgrade capacity before any new dedicated EV circuit.',
        'Permit/inspection path',
      ],
      installerHandoff: {
        title: 'Panel capacity evaluation required before EV charger recommendation',
        bullets: [
          `Proposed wall: ${graph.proposedEvseLocation.wall}`,
          'Require a panel, subpanel, or service upgrade evaluation before selecting an EV charger or dedicated circuit.',
        ],
      },
      toolRun: {
        id: `tool-engineering-${graph.assessmentId}`,
        toolName: 'runEngineeringScenario',
        version: TOOL_VERSION,
        inputSummary: `${serviceAmps} A service; 0 spare spaces; ${route.value} ${route.unit} route; panel ${panel.status}/${panel.sourceType}; route ${route.status}/${route.sourceType}`,
        resultStatus: 'conditional',
        warnings: ['No spare breaker spaces are available; this screen does not assert that a new dedicated circuit can fit.'],
        assumptions: [],
        evidenceIds,
        output: { panelCapacityEvaluationRequired: true },
        timestamp,
      },
      disclaimer: SAFETY_DISCLAIMER,
    });
  }

  const constrained = serviceAmps <= 100 || spareBreakerSpaces < 4;
  const chargerCurrentAmps = constrained ? 16 : 32;
  const label = constrained ? '16 A managed or low-current charger' : '32 A hardwired charger';
  const status = 'professional_verification_required' as const;

  return EngineeringScenarioResultSchema.parse({
    origin,
    status,
    recommendation: {
      chargerCurrentAmps,
      label,
      highCurrentRecommended: false,
    },
    missingInputs: [],
    unresolvedRequirements: constrained
      ? ['True load calculation', 'Panel compatibility and condition review', 'Final electrician review']
      : ['True load calculation', 'Breaker compatibility', 'Final electrician review'],
    professionalVerificationItems: constrained
      ? ['Panel/service verification', 'Conduit path and breaker selection', 'Permit/inspection path']
      : ['Service and panel confirmation', 'Conductor and breaker selection'],
    installerHandoff: {
      title: 'Preliminary EV charger handoff',
      bullets: [`Proposed wall: ${graph.proposedEvseLocation.wall}`, `Recommended preliminary path: ${label}`],
    },
    toolRun: {
      id: `tool-engineering-${graph.assessmentId}`,
      toolName: 'runEngineeringScenario',
      version: TOOL_VERSION,
      inputSummary: `${serviceAmps} A service; ${spareBreakerSpaces} spare spaces; ${route.value} ${route.unit} route; panel ${panel.status}/${panel.sourceType}; route ${route.status}/${route.sourceType}`,
      resultStatus: 'conditional',
      warnings: ['This is a preliminary deterministic screen, not a code compliance determination.'],
      assumptions: ['Visible panel facts are preliminary pending professional verification.'],
      evidenceIds,
      output: { recommendedScenario: label, chargerCurrentAmps, highCurrentRecommended: false },
      timestamp,
    },
    disclaimer: SAFETY_DISCLAIMER,
  });
}

/** Maps professional verification required to conditional because EngineeringScenarioSchema has no professional_verification_required status. */
export function applyEngineeringScenario(
  input: SiteGraphV0,
  resultInput: EngineeringScenarioResult,
  expectedCalculationTimestamp?: string,
): SiteGraphV0 {
  const graph = SiteGraphSchema.parse(input);
  const result = EngineeringScenarioResultSchema.parse(resultInput);
  const trustedTimestamp = expectedCalculationTimestamp === undefined
    ? result.origin.calculationTimestamp
    : z.string().datetime({ offset: true }).parse(expectedCalculationTimestamp);
  if (result.origin.assessmentId !== graph.assessmentId) {
    throw new Error('Result assessment origin does not match the input assessment.');
  }
  if (result.origin.calculationTimestamp !== trustedTimestamp || result.toolRun.timestamp !== trustedTimestamp) {
    throw new Error('Result does not match the trusted calculation timestamp.');
  }
  const currentInputSnapshot = snapshotEngineeringInputs(graph);
  const currentInputFingerprint = fingerprintEngineeringInputs(currentInputSnapshot);
  if (
    result.origin.inputFingerprint !== fingerprintEngineeringInputs(result.origin.inputSnapshot)
    || result.origin.inputFingerprint !== currentInputFingerprint
    || JSON.stringify(result.origin.inputSnapshot) !== JSON.stringify(currentInputSnapshot)
  ) {
    throw new Error('Result inputs do not match the current calculation-relevant graph facts.');
  }
  const canonicalResult = runEngineeringScenario(graph, trustedTimestamp);
  if (!isDeepStrictEqual(result, canonicalResult)) {
    throw new Error('Result does not match the canonical deterministic calculation.');
  }
  const scenarioStatus = result.status === 'insufficient_data' ? 'insufficient_data' : 'conditional';
  const persistedToolRun = ToolRunSchema.parse({
    ...result.toolRun,
    output: {
      ...result.toolRun.output,
      origin: result.origin,
    },
  });
  const scenarioId = `engineering-scenario-${graph.assessmentId}`;
  const scenario = {
    id: scenarioId,
    label: result.recommendation.label ?? 'Engineering scenario pending required facts',
    ...(result.recommendation.chargerCurrentAmps === null
      ? {}
      : { chargerCurrentAmps: result.recommendation.chargerCurrentAmps }),
    status: scenarioStatus,
    resultSummary: result.status === 'insufficient_data'
      ? 'Cannot derive an engineering recommendation until the listed facts are usable.'
      : `${result.recommendation.label} is preliminary and requires professional verification.`,
    requirements: result.unresolvedRequirements,
    warnings: [result.disclaimer],
    assumptions: result.toolRun.assumptions,
    evidenceIds: result.toolRun.evidenceIds,
    timestamp: result.toolRun.timestamp,
  };

  return SiteGraphSchema.parse({
    ...graph,
    toolRuns: [
      ...graph.toolRuns.filter((existing) => existing.id !== persistedToolRun.id),
      persistedToolRun,
    ],
    engineeringScenarios: [
      ...graph.engineeringScenarios.filter((existing) => existing.id !== scenarioId),
      scenario,
    ],
    finalAssessment: {
      status: result.status,
      summary: scenario.resultSummary,
      unresolvedRequirements: result.unresolvedRequirements,
      professionalVerificationItems: result.professionalVerificationItems,
      installerHandoff: result.installerHandoff,
      timestamp: result.toolRun.timestamp,
    },
  });
}
