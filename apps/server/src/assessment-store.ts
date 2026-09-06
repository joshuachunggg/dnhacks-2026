import {
  AssessmentEventSchema,
  ObservationAddedEventSchema,
  SiteGraphSchema,
} from '../../../packages/schemas/src/sitegraph';
import type { SiteGraphV0 } from '../../../packages/schemas/src/sitegraph';
import {
  applyEngineeringScenario as applyCanonicalEngineeringScenario,
  type EngineeringScenarioResult,
} from './engineering-calculator';
import {
  applyCostScenario as applyCanonicalCostScenario,
  type CostScenarioResult,
} from './cost-calculator';

export class AssessmentNotFoundError extends Error {
  constructor(assessmentId: string) {
    super(`Assessment not found: ${assessmentId}`);
    this.name = 'AssessmentNotFoundError';
  }
}

export interface InMemoryAssessmentStore {
  create(input: unknown): SiteGraphV0;
  get(assessmentId: string): SiteGraphV0 | undefined;
  appendEvent(assessmentId: string, input: unknown): SiteGraphV0;
  appendObservationEvent(assessmentId: string, input: unknown): SiteGraphV0;
  applyEngineeringScenario(assessmentId: string, result: EngineeringScenarioResult, calculationTimestamp?: string): SiteGraphV0;
  applyCostScenario(assessmentId: string, result: CostScenarioResult, calculationTimestamp?: string): SiteGraphV0;
}

export function createInMemoryAssessmentStore(): InMemoryAssessmentStore {
  const assessments = new Map<string, SiteGraphV0>();

  return {
    create(input: unknown): SiteGraphV0 {
      const assessment = SiteGraphSchema.parse(input);
      assessments.set(assessment.assessmentId, assessment);
      return assessment;
    },

    get(assessmentId: string): SiteGraphV0 | undefined {
      return assessments.get(assessmentId);
    },

    appendEvent(assessmentId: string, input: unknown): SiteGraphV0 {
      const event = AssessmentEventSchema.parse(input);
      const current = assessments.get(assessmentId);
      if (!current) {
        throw new AssessmentNotFoundError(assessmentId);
      }

      const replaceById = <T extends { id: string }>(items: T[], replacement: T): T[] => [
        ...items.filter((item) => item.id !== replacement.id),
        replacement,
      ];
      const requireKnownEvidence = (evidenceIds: string[]) => {
        if (!evidenceIds.every((evidenceId) => current.evidence.some((evidence) => evidence.id === evidenceId))) {
          throw new Error('Event references evidence that is not registered on the assessment.');
        }
      };
      const addImmutableEvidence = (evidence: typeof current.evidence, item: typeof current.evidence[number]) => {
        const existing = evidence.find((candidate) => candidate.id === item.id);
        if (existing && JSON.stringify(existing) !== JSON.stringify(item)) {
          throw new Error('Evidence records are immutable and cannot be rebound.');
        }
        return existing ? evidence : [...evidence, item];
      };

      let candidate: SiteGraphV0;
      switch (event.eventName) {
        case 'observation.added':
          candidate = {
            ...current,
            observations: replaceById(current.observations, event.payload),
          };
          break;
        case 'spatial.capture.recorded':
          candidate = {
            ...current,
            spatialCaptures: replaceById(current.spatialCaptures, event.payload),
            evidence: event.payload.evidence.reduce(addImmutableEvidence, current.evidence),
          };
          break;
        case 'visual.frame.recorded':
          candidate = {
            ...current,
            visualFrames: replaceById(current.visualFrames, event.payload),
            evidence: addImmutableEvidence(current.evidence, event.payload.evidence),
          };
          break;
        case 'spatial.object.proposed':
          requireKnownEvidence(event.payload.evidenceIds);
          candidate = {
            ...current,
            spatialObjects: replaceById(current.spatialObjects, event.payload),
          };
          break;
        case 'measurement.recorded':
          requireKnownEvidence(event.payload.evidenceIds);
          candidate = {
            ...current,
            measurements: replaceById(current.measurements, event.payload),
          };
          break;
        case 'evse_location.confirmed':
          requireKnownEvidence(event.payload.evidenceIds);
          candidate = {
            ...current,
            proposedEvseLocation: event.payload,
          };
          break;
        case 'spatial.location.confirmed':
          requireKnownEvidence(event.payload.evidenceIds);
          candidate = {
            ...current,
            spatialLocations: replaceById(current.spatialLocations, event.payload),
          };
          break;
        case 'route.waypoints.recorded': {
          const waypoints = [...event.payload.waypoints].sort((left, right) => left.sequence - right.sequence);
          if (new Set(waypoints.map((waypoint) => waypoint.sequence)).size !== waypoints.length) {
            throw new Error('Route waypoint sequences must be unique.');
          }
          if (new Set(waypoints.map((waypoint) => waypoint.coordinateSpaceId)).size !== 1) {
            throw new Error('Route waypoints must use one coordinate space.');
          }
          waypoints.forEach((waypoint) => requireKnownEvidence(waypoint.evidenceIds));
          const routeEvidenceIds = [...new Set(waypoints.flatMap((waypoint) => waypoint.evidenceIds))];
          const routeMeters = waypoints.slice(1).reduce((total, waypoint, index) => {
            const previous = waypoints[index].positionMeters;
            const currentPoint = waypoint.positionMeters;
            return total + Math.hypot(
              currentPoint.x - previous.x,
              currentPoint.y - previous.y,
              currentPoint.z - previous.z,
            );
          }, 0);
          const measurement = {
            id: `measurement-route-${event.payload.id}`,
            kind: 'route_length' as const,
            value: routeMeters * 3.28084,
            unit: 'ft',
            status: 'confirmed' as const,
            sourceType: 'measured' as const,
            evidenceIds: routeEvidenceIds,
            timestamp: event.timestamp,
            producer: event.producer,
            assumptions: ['Derived from confirmed user-selected route waypoints in one RoomPlan coordinate space.'],
            notes: [`Route waypoint set: ${event.payload.id}`],
          };
          candidate = {
            ...current,
            routeWaypoints: waypoints,
            measurements: replaceById(current.measurements, measurement),
          };
          break;
        }
        case 'panel.facts.confirmed': {
          if (event.payload.panelId !== current.electricalPanel.id) {
            throw new Error('Panel fact confirmation does not match the assessment panel.');
          }
          event.payload.facts.forEach((fact) => requireKnownEvidence(fact.evidenceIds));
          const factFor = (field: 'service_amps' | 'bus_rating_amps' | 'spare_breaker_spaces') =>
            event.payload.facts.find((fact) => fact.field === field);
          const serviceAmps = factFor('service_amps');
          const busRatingAmps = factFor('bus_rating_amps');
          const spareBreakerSpaces = factFor('spare_breaker_spaces');
          const evidenceIds = [...new Set(event.payload.facts.flatMap((fact) => fact.evidenceIds))];
          candidate = {
            ...current,
            panelFactConfirmations: event.payload.facts.reduce(
              (facts, fact) => replaceById(facts, fact),
              current.panelFactConfirmations,
            ),
            electricalPanel: {
              ...current.electricalPanel,
              status: 'confirmed',
              sourceType: 'user_supplied',
              evidenceIds,
              timestamp: event.timestamp,
              producer: event.producer,
              ...(serviceAmps ? { serviceAmps: serviceAmps.value } : {}),
              ...(busRatingAmps ? { busRatingAmps: busRatingAmps.value } : {}),
              ...(spareBreakerSpaces ? { spareBreakerSpaces: spareBreakerSpaces.value } : {}),
            },
          };
          break;
        }
      }

      const updated = SiteGraphSchema.parse(candidate);
      assessments.set(assessmentId, updated);
      return updated;
    },

    appendObservationEvent(assessmentId: string, input: unknown): SiteGraphV0 {
      ObservationAddedEventSchema.parse(input);
      return this.appendEvent(assessmentId, input);
    },

    applyEngineeringScenario(assessmentId: string, result: EngineeringScenarioResult, calculationTimestamp?: string): SiteGraphV0 {
      const current = assessments.get(assessmentId);
      if (!current) {
        throw new AssessmentNotFoundError(assessmentId);
      }

      const updated = applyCanonicalEngineeringScenario(current, result, calculationTimestamp);
      assessments.set(assessmentId, updated);
      return updated;
    },

    applyCostScenario(assessmentId: string, result: CostScenarioResult, calculationTimestamp?: string): SiteGraphV0 {
      const current = assessments.get(assessmentId);
      if (!current) {
        throw new AssessmentNotFoundError(assessmentId);
      }

      const updated = applyCanonicalCostScenario(current, result, calculationTimestamp);
      assessments.set(assessmentId, updated);
      return updated;
    },
  };
}

export const assessmentStore = createInMemoryAssessmentStore();
