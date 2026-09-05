import { z } from 'zod';

import {
  assessmentStore,
} from '../../../../../../../apps/server/src/assessment-store';
import { runEngineeringScenario } from '../../../../../../../apps/server/src/engineering-calculator';

interface AssessmentRouteContext {
  params: Promise<{ assessmentId: string }>;
}

const RunEngineeringScenarioRequestSchema = z.object({}).strict();

function validationErrorResponse(error: z.ZodError): Response {
  return Response.json(
    { error: 'validation_error', details: error.issues },
    { status: 400 },
  );
}

export async function POST(request: Request, context: AssessmentRouteContext): Promise<Response> {
  let input: unknown;
  try {
    input = await request.json();
  } catch {
    return Response.json({ error: 'invalid_json' }, { status: 400 });
  }

  try {
    RunEngineeringScenarioRequestSchema.parse(input);
    const { assessmentId } = await context.params;
    const assessment = assessmentStore.get(assessmentId);
    if (!assessment) {
      return Response.json({ error: 'assessment_not_found' }, { status: 404 });
    }
    const result = runEngineeringScenario(assessment, new Date().toISOString());
    const updatedAssessment = assessmentStore.applyEngineeringScenario(assessmentId, result);
    return Response.json({ assessment: updatedAssessment });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return validationErrorResponse(error);
    }
    throw error;
  }
}
