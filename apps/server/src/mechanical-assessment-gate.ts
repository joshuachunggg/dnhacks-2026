import { z } from 'zod';

import { SiteGraphSchema, type SiteGraphV0 } from '../../../packages/schemas/src/sitegraph';
import { runEngineeringScenario, type EngineeringScenarioResult } from './engineering-calculator';

export const MissingInputActionSchema = z.enum([
  'capture_panel_image',
  'confirm_panel_facts',
  'place_panel_location',
  'place_evse_location',
  'record_route_waypoints',
  'finish_and_review',
]);

export const MechanicalAssessmentGateResultSchema = z.discriminatedUnion('status', [
  z.object({
    status: z.literal('needs_input'),
    nextAction: MissingInputActionSchema.exclude(['finish_and_review']),
    message: z.string(),
  }).strict(),
  z.object({
    status: z.literal('ready'),
    nextAction: z.literal('finish_and_review'),
    result: z.unknown(),
    planningOnly: z.boolean(),
  }).strict(),
]);

export type MissingInputAction = z.infer<typeof MissingInputActionSchema>;
export type MechanicalAssessmentGateResult = {
  status: 'needs_input';
  nextAction: Exclude<MissingInputAction, 'finish_and_review'>;
  message: string;
} | {
  status: 'ready';
  nextAction: 'finish_and_review';
  result: EngineeringScenarioResult;
  planningOnly: boolean;
};

function evidenceExists(graph: SiteGraphV0, evidenceIds: string[]): boolean {
  return evidenceIds.length > 0 && evidenceIds.every((id) => graph.evidence.some((evidence) => evidence.id === id));
}

function distanceMeters(left: { x: number; y: number; z: number }, right: { x: number; y: number; z: number }): number {
  return Math.hypot(left.x - right.x, left.y - right.y, left.z - right.z);
}

export function evaluateMechanicalAssessmentGate(
  input: unknown,
  calculationTimestamp: string,
): MechanicalAssessmentGateResult {
  const graph = SiteGraphSchema.parse(input);
  const panelFrame = graph.visualFrames.find((frame) => evidenceExists(graph, [frame.evidence.id]));
  if (!panelFrame) {
    return { status: 'needs_input', nextAction: 'capture_panel_image', message: 'Capture an electrical-panel image before confirming panel facts.' };
  }

  const panelFactFields = new Set(
    graph.panelFactConfirmations
      .filter((fact) => fact.status === 'confirmed' && fact.sourceType === 'user_supplied' && evidenceExists(graph, fact.evidenceIds))
      .map((fact) => fact.field),
  );
  if (!panelFactFields.has('service_amps') || !panelFactFields.has('spare_breaker_spaces')) {
    return { status: 'needs_input', nextAction: 'confirm_panel_facts', message: 'Confirm visible service amps and spare breaker spaces from the panel image. You may record an approximation for planning, but it cannot unlock an engineering recommendation.' };
  }

  const panelLocation = graph.spatialLocations.find((location) => location.kind === 'electrical_panel' && evidenceExists(graph, location.evidenceIds));
  if (!panelLocation) {
    return { status: 'needs_input', nextAction: 'place_panel_location', message: 'Select the electrical-panel location in the room model.' };
  }
  const evseLocation = graph.spatialLocations.find((location) => location.kind === 'evse' && evidenceExists(graph, location.evidenceIds));
  if (!evseLocation) {
    return { status: 'needs_input', nextAction: 'place_evse_location', message: 'Select the proposed EVSE location in the room model.' };
  }
  const routeConnectsLocations = graph.routeWaypoints.length >= 2
    && graph.routeWaypoints.every((waypoint) => waypoint.coordinateSpaceId === panelLocation.coordinateSpaceId)
    && panelLocation.coordinateSpaceId === evseLocation.coordinateSpaceId
    && distanceMeters(graph.routeWaypoints[0].positionMeters, panelLocation.positionMeters) <= 1
    && distanceMeters(graph.routeWaypoints.at(-1)!.positionMeters, evseLocation.positionMeters) <= 1;
  if (!routeConnectsLocations || !graph.measurements.some((measurement) => (
    measurement.kind === 'route_length'
    && measurement.status === 'confirmed'
    && measurement.sourceType === 'measured'
    && measurement.unit === 'ft'
    && measurement.value > 0
    && evidenceExists(graph, measurement.evidenceIds)
  ))) {
    return { status: 'needs_input', nextAction: 'record_route_waypoints', message: 'Select at least two route waypoints so the app can record the feet-based route measurement.' };
  }

  const result = runEngineeringScenario(graph, calculationTimestamp);
  if (result.status === 'insufficient_data') {
    return { status: 'needs_input', nextAction: 'confirm_panel_facts', message: result.installerHandoff.bullets[0] ?? 'Confirm the required panel facts from the evidence image.' };
  }
  const planningOnly = graph.panelFactConfirmations.some((fact) => fact.notes.some((note) => note.includes('planning approximation')));
  return { status: 'ready', nextAction: 'finish_and_review', result, planningOnly };
}
