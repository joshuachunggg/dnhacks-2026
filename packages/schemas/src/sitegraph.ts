import { z } from 'zod';

export const SiteGraphVersion = '0.1.0' as const;

export const ValueStatusSchema = z.enum([
  'proposed',
  'confirmed',
  'contradicted',
  'superseded',
  'professionally_verified',
  'calculated',
]);

export const SourceTypeSchema = z.enum([
  'measured',
  'visually_observed',
  'ocr_extracted',
  'user_supplied',
  'externally_retrieved',
  'inferred',
  'calculated',
  'assumed',
  'professionally_verified',
]);

export const EvidenceRefSchema = z.object({
  id: z.string(),
  type: z.enum(['image_frame', 'measurement', 'source_url', 'note']),
  label: z.string(),
  uri: z.string().optional(),
}).strict();

export const ObservationSchema = z.object({
  id: z.string(),
  kind: z.enum(['panel', 'location', 'load', 'label_text', 'jurisdiction', 'other']),
  field: z.string(),
  value: z.union([z.string(), z.number(), z.boolean()]),
  unit: z.string().optional(),
  status: ValueStatusSchema,
  sourceType: SourceTypeSchema,
  confidence: z.number().min(0).max(1).optional(),
  evidenceIds: z.array(z.string()),
  timestamp: z.string(),
  producer: z.string(),
  assumptions: z.array(z.string()).default([]),
  notes: z.array(z.string()).default([]),
  supersedes: z.string().optional(),
}).strict();

export const ObservationAddedEventSchema = z.object({
  eventId: z.string(),
  eventName: z.literal('observation.added'),
  timestamp: z.string(),
  producer: z.string(),
  schemaVersion: z.literal(SiteGraphVersion),
  payload: ObservationSchema,
}).strict();

export const MeasurementSchema = z.object({
  id: z.string(),
  kind: z.enum(['route_length', 'height', 'distance', 'other']),
  value: z.number(),
  unit: z.string(),
  status: ValueStatusSchema,
  sourceType: SourceTypeSchema,
  confidence: z.number().min(0).max(1).optional(),
  evidenceIds: z.array(z.string()),
  timestamp: z.string(),
  producer: z.string(),
  assumptions: z.array(z.string()).default([]),
  notes: z.array(z.string()).default([]),
}).strict();

export const ToolRunSchema = z.object({
  id: z.string(),
  toolName: z.string(),
  version: z.string(),
  inputSummary: z.string(),
  resultStatus: z.enum(['pass', 'fail', 'conditional', 'insufficient_data']),
  warnings: z.array(z.string()).default([]),
  assumptions: z.array(z.string()).default([]),
  evidenceIds: z.array(z.string()).default([]),
  output: z.record(z.string(), z.unknown()),
  timestamp: z.string(),
}).strict();

export const ScenarioLineItemSchema = z.object({
  id: z.string(),
  label: z.string(),
  quantity: z.number(),
  unit: z.string(),
  low: z.number(),
  expected: z.number(),
  high: z.number(),
  currency: z.literal('USD'),
  source: z.string(),
  assumptions: z.array(z.string()).default([]),
}).strict();

export const CostScenarioSchema = z.object({
  id: z.string(),
  label: z.string(),
  status: z.enum(['pass', 'fail', 'conditional', 'insufficient_data']),
  totalLow: z.number(),
  totalExpected: z.number(),
  totalHigh: z.number(),
  currency: z.literal('USD'),
  lineItems: z.array(ScenarioLineItemSchema),
  assumptions: z.array(z.string()).default([]),
  warnings: z.array(z.string()).default([]),
  evidenceIds: z.array(z.string()).default([]),
}).strict();

export const AssessmentStatusSchema = z.enum([
  'pass',
  'conditional',
  'insufficient_data',
  'professional_verification_required',
]);

export const SiteGraphSchema = z.object({
  schemaVersion: z.literal(SiteGraphVersion),
  assessmentId: z.string(),
  evidence: z.array(EvidenceRefSchema).default([]),
  site: z.object({
    id: z.string(),
    label: z.string(),
    address: z.string(),
    jurisdiction: z.object({
      city: z.string(),
      county: z.string(),
      state: z.string(),
      ahj: z.string(),
    }).strict(),
    utility: z.string().optional(),
  }).strict(),
  proposedEvseLocation: z.object({
    id: z.string(),
    label: z.string(),
    wall: z.string(),
    status: ValueStatusSchema,
    sourceType: SourceTypeSchema,
    confidence: z.number().min(0).max(1).optional(),
    evidenceIds: z.array(z.string()),
    timestamp: z.string(),
    producer: z.string(),
    assumptions: z.array(z.string()).default([]),
    notes: z.array(z.string()).default([]),
  }).strict(),
  electricalPanel: z.object({
    id: z.string(),
    label: z.string(),
    status: ValueStatusSchema,
    sourceType: SourceTypeSchema,
    confidence: z.number().min(0).max(1).optional(),
    evidenceIds: z.array(z.string()),
    timestamp: z.string(),
    producer: z.string(),
    manufacturer: z.string().optional(),
    modelFamily: z.string().optional(),
    serviceVoltage: z.number().optional(),
    serviceAmps: z.number().int().positive().optional(),
    busRatingAmps: z.number().int().positive().optional(),
    breakerSpaceCount: z.number().int().nonnegative().optional(),
    spareBreakerSpaces: z.number().int().nonnegative().optional(),
    visibleConditionNotes: z.array(z.string()).default([]),
    assumptions: z.array(z.string()).default([]),
    notes: z.array(z.string()).default([]),
  }).strict(),
  measurements: z.array(MeasurementSchema),
  observations: z.array(ObservationSchema),
  engineeringScenarios: z.array(z.object({
    id: z.string(),
    label: z.string(),
    chargerCurrentAmps: z.number().int().positive().optional(),
    status: z.enum(['pass', 'fail', 'conditional', 'insufficient_data']),
    resultSummary: z.string(),
    requirements: z.array(z.string()).default([]),
    warnings: z.array(z.string()).default([]),
    assumptions: z.array(z.string()).default([]),
    evidenceIds: z.array(z.string()).default([]),
    timestamp: z.string(),
  }).strict()),
  toolRuns: z.array(ToolRunSchema),
  costScenarios: z.array(CostScenarioSchema),
  finalAssessment: z.object({
    status: AssessmentStatusSchema,
    summary: z.string(),
    unresolvedRequirements: z.array(z.string()),
    professionalVerificationItems: z.array(z.string()),
    installerHandoff: z.object({
      title: z.string(),
      bullets: z.array(z.string()),
    }).strict(),
    timestamp: z.string(),
  }).strict(),
}).strict();

export type SiteGraphV0 = z.infer<typeof SiteGraphSchema>;
export type EvidenceRef = z.infer<typeof EvidenceRefSchema>;
export type Observation = z.infer<typeof ObservationSchema>;
export type ObservationAddedEvent = z.infer<typeof ObservationAddedEventSchema>;
export type Measurement = z.infer<typeof MeasurementSchema>;
export type ToolRun = z.infer<typeof ToolRunSchema>;
export type CostScenario = z.infer<typeof CostScenarioSchema>;
export type AssessmentStatus = z.infer<typeof AssessmentStatusSchema>;

export function decodeSiteGraph(input: unknown): SiteGraphV0 {
  return SiteGraphSchema.parse(input);
}
