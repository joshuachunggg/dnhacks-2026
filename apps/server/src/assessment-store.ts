import {
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

    appendObservationEvent(assessmentId: string, input: unknown): SiteGraphV0 {
      const event = ObservationAddedEventSchema.parse(input);
      const current = assessments.get(assessmentId);
      if (!current) {
        throw new AssessmentNotFoundError(assessmentId);
      }

      const updated = SiteGraphSchema.parse({
        ...current,
        observations: [...current.observations, event.payload],
      });
      assessments.set(assessmentId, updated);
      return updated;
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
