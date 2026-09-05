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
            evidence: event.payload.evidence.reduce(
              (evidence, item) => replaceById(evidence, item),
              current.evidence,
            ),
          };
          break;
        case 'measurement.recorded':
          candidate = {
            ...current,
            measurements: replaceById(current.measurements, event.payload),
          };
          break;
        case 'evse_location.confirmed':
          candidate = {
            ...current,
            proposedEvseLocation: event.payload,
          };
          break;
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
