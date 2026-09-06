import { z } from 'zod';

import { assessmentStore } from '../../../../../../apps/server/src/assessment-store';
import { evaluateMechanicalAssessmentGate } from '../../../../../../apps/server/src/mechanical-assessment-gate';

interface AssessmentRouteContext {
  params: Promise<{ assessmentId: string }>;
}

const GateRequestSchema = z.object({}).strict();

export async function POST(request: Request, context: AssessmentRouteContext): Promise<Response> {
  let input: unknown;
  try {
    input = await request.json();
  } catch {
    return Response.json({ error: 'invalid_json' }, { status: 400 });
  }

  try {
    GateRequestSchema.parse(input);
    const { assessmentId } = await context.params;
    const assessment = assessmentStore.get(assessmentId);
    if (!assessment) return Response.json({ error: 'assessment_not_found' }, { status: 404 });

    const calculationTimestamp = new Date().toISOString();
    const gate = evaluateMechanicalAssessmentGate(assessment, calculationTimestamp);
    if (gate.status === 'needs_input') return Response.json({ gate });

    const updatedAssessment = assessmentStore.applyEngineeringScenario(assessmentId, gate.result, calculationTimestamp);
    return Response.json({ gate, assessment: updatedAssessment });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return Response.json({ error: 'validation_error', details: error.issues }, { status: 400 });
    }
    throw error;
  }
}
