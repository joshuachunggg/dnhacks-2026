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
  type: z.enum(['image_frame', 'measurement', 'room_model', 'source_url', 'note']),
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

export const ProposedEvseLocationSchema = z.object({
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
}).strict();

export const SpatialLocationSchema = z.object({
  id: z.string(),
  kind: z.enum(['electrical_panel', 'evse']),
  label: z.string().min(1),
  coordinateSpaceId: z.string().min(1),
  positionMeters: z.object({ x: z.number(), y: z.number(), z: z.number() }).strict(),
  surface: z.enum(['wall', 'floor', 'ceiling', 'unknown']),
  status: z.literal('confirmed'),
  sourceType: z.enum(['measured', 'user_supplied']),
  evidenceIds: z.array(z.string()).min(1),
  timestamp: z.string(),
  producer: z.string(),
  assumptions: z.array(z.string()).default([]),
  notes: z.array(z.string()).default([]),
}).strict();

export const RouteWaypointSchema = z.object({
  id: z.string(),
  sequence: z.number().int().nonnegative(),
  coordinateSpaceId: z.string().min(1),
  positionMeters: z.object({ x: z.number(), y: z.number(), z: z.number() }).strict(),
  surface: z.enum(['wall', 'floor', 'ceiling', 'unknown']),
  status: z.literal('confirmed'),
  sourceType: z.enum(['measured', 'user_supplied']),
  evidenceIds: z.array(z.string()).min(1),
  timestamp: z.string(),
  producer: z.string(),
  assumptions: z.array(z.string()).default([]),
  notes: z.array(z.string()).default([]),
}).strict();

const PanelFactFieldSchema = z.enum(['service_amps', 'bus_rating_amps', 'spare_breaker_spaces']);
export const PanelFactConfirmationSchema = z.object({
  id: z.string(),
  field: PanelFactFieldSchema,
  value: z.number().int().nonnegative(),
  unit: z.literal('A').optional(),
  status: z.literal('confirmed'),
  sourceType: z.literal('user_supplied'),
  evidenceIds: z.array(z.string()).min(1),
  timestamp: z.string(),
  producer: z.string(),
  notes: z.array(z.string()).default([]),
}).strict();

export const SpatialArtifactSchema = z.object({
  id: z.string(),
  kind: z.enum(['roomplan_json', 'room_usdz', 'panel_image', 'room_preview']),
  uri: z.string().url(),
  contentType: z.string().min(1),
  byteLength: z.number().int().positive(),
  sha256: z.string().regex(/^[a-f0-9]{64}$/i, 'Expected a SHA-256 hex digest'),
}).strict();

export const RoomPlanObjectTypeSchema = z.object({
  category: z.string().min(1).max(100),
  count: z.number().int().positive(),
}).strict();

export const SpatialCaptureSchema = z.object({
  id: z.string(),
  kind: z.enum(['roomplan_room']),
  status: z.enum(['proposed', 'confirmed']),
  coordinateSpaceId: z.string().min(1),
  timestamp: z.string(),
  producer: z.string(),
  detectedObjectTypes: z.array(RoomPlanObjectTypeSchema).default([]),
  artifacts: z.array(SpatialArtifactSchema).min(1),
  evidence: z.array(EvidenceRefSchema).min(1),
}).strict();

export const VisualFrameSchema = z.object({
  id: z.string(),
  captureId: z.string().optional(),
  coordinateSpaceId: z.string().min(1),
  timestamp: z.string(),
  producer: z.string(),
  artifact: SpatialArtifactSchema.extend({
    kind: z.literal('panel_image'),
  }).strict(),
  evidence: EvidenceRefSchema.extend({
    type: z.literal('image_frame'),
  }).strict(),
}).strict();

const NormalizedBoundingBoxSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  width: z.number().positive().max(1),
  height: z.number().positive().max(1),
}).strict().refine(
  ({ x, y, width, height }) => x + width <= 1 && y + height <= 1,
  'Bounding box must remain within the image bounds',
);

export const SpatialObjectSchema = z.object({
  id: z.string(),
  kind: z.enum(['electrical_panel', 'outlet', 'table', 'other']),
  label: z.string().min(1),
  status: ValueStatusSchema,
  sourceType: SourceTypeSchema,
  confidence: z.number().min(0).max(1).optional(),
  coordinateSpaceId: z.string().min(1),
  geometry: z.object({
    positionMeters: z.object({
      x: z.number(),
      y: z.number(),
      z: z.number(),
    }).strict(),
    surface: z.enum(['wall', 'floor', 'ceiling', 'unknown']),
  }).strict(),
  detections: z.array(z.object({
    evidenceId: z.string(),
    model: z.string().min(1),
    imageBoundingBox: NormalizedBoundingBoxSchema,
    confidence: z.number().min(0).max(1),
  }).strict()).min(1),
  evidenceIds: z.array(z.string()).min(1),
  timestamp: z.string(),
  producer: z.string(),
  assumptions: z.array(z.string()).default([]),
  notes: z.array(z.string()).default([]),
}).strict();

const AssessmentEventBaseSchema = z.object({
  eventId: z.string(),
  timestamp: z.string(),
  producer: z.string(),
  schemaVersion: z.literal(SiteGraphVersion),
});

export const SpatialCaptureRecordedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('spatial.capture.recorded'),
  payload: SpatialCaptureSchema,
}).strict();

export const VisualFrameRecordedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('visual.frame.recorded'),
  payload: VisualFrameSchema,
}).strict();

export const SpatialObjectProposedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('spatial.object.proposed'),
  payload: SpatialObjectSchema.extend({
    status: z.literal('proposed'),
  }).strict(),
}).strict();

export const MeasurementRecordedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('measurement.recorded'),
  payload: MeasurementSchema,
}).strict();

export const EvseLocationConfirmedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('evse_location.confirmed'),
  payload: ProposedEvseLocationSchema.extend({
    status: z.literal('confirmed'),
  }).strict(),
}).strict();

export const SpatialLocationConfirmedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('spatial.location.confirmed'),
  payload: SpatialLocationSchema,
}).strict();

export const RouteWaypointsRecordedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('route.waypoints.recorded'),
  payload: z.object({ id: z.string(), waypoints: z.array(RouteWaypointSchema).min(2) }).strict(),
}).strict();

export const PanelFactsConfirmedEventSchema = AssessmentEventBaseSchema.extend({
  eventName: z.literal('panel.facts.confirmed'),
  payload: z.object({
    panelId: z.string(),
    facts: z.array(PanelFactConfirmationSchema).min(1).superRefine((facts, context) => {
      const fields = new Set(facts.map((fact) => fact.field));
      if (facts.length !== fields.size) context.addIssue({ code: 'custom', message: 'Panel fact fields must not be duplicated' });
    }),
  }).strict(),
}).strict();

export const AssessmentEventSchema = z.discriminatedUnion('eventName', [
  ObservationAddedEventSchema,
  SpatialCaptureRecordedEventSchema,
  VisualFrameRecordedEventSchema,
  SpatialObjectProposedEventSchema,
  MeasurementRecordedEventSchema,
  EvseLocationConfirmedEventSchema,
  SpatialLocationConfirmedEventSchema,
  RouteWaypointsRecordedEventSchema,
  PanelFactsConfirmedEventSchema,
]);

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
  spatialCaptures: z.array(SpatialCaptureSchema).default([]),
  visualFrames: z.array(VisualFrameSchema).default([]),
  spatialObjects: z.array(SpatialObjectSchema).default([]),
  spatialLocations: z.array(SpatialLocationSchema).default([]),
  routeWaypoints: z.array(RouteWaypointSchema).default([]),
  panelFactConfirmations: z.array(PanelFactConfirmationSchema).default([]),
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
  proposedEvseLocation: ProposedEvseLocationSchema,
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
export type AssessmentEvent = z.infer<typeof AssessmentEventSchema>;
export type Measurement = z.infer<typeof MeasurementSchema>;
export type SpatialArtifact = z.infer<typeof SpatialArtifactSchema>;
export type SpatialCapture = z.infer<typeof SpatialCaptureSchema>;
export type SpatialLocation = z.infer<typeof SpatialLocationSchema>;
export type RouteWaypoint = z.infer<typeof RouteWaypointSchema>;
export type PanelFactConfirmation = z.infer<typeof PanelFactConfirmationSchema>;
export type ToolRun = z.infer<typeof ToolRunSchema>;
export type CostScenario = z.infer<typeof CostScenarioSchema>;
export type AssessmentStatus = z.infer<typeof AssessmentStatusSchema>;

export function decodeSiteGraph(input: unknown): SiteGraphV0 {
  return SiteGraphSchema.parse(input);
}
