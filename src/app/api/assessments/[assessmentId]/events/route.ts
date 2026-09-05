import { z } from 'zod';

import {
  AssessmentNotFoundError,
  assessmentStore,
} from '../../../../../../apps/server/src/assessment-store';

interface AssessmentRouteContext {
  params: Promise<{ assessmentId: string }>;
}

export async function POST(request: Request, context: AssessmentRouteContext): Promise<Response> {
  let input: unknown;
  try {
    input = await request.json();
  } catch {
    return Response.json({ error: 'invalid_json' }, { status: 400 });
  }

  const { assessmentId } = await context.params;
  try {
    const assessment = assessmentStore.appendObservationEvent(assessmentId, input);
    return Response.json({ assessment });
  } catch (error) {
    if (error instanceof AssessmentNotFoundError) {
      return Response.json({ error: 'assessment_not_found' }, { status: 404 });
    }
    if (error instanceof z.ZodError) {
      return Response.json(
        { error: 'validation_error', details: error.issues },
        { status: 400 },
      );
    }
    throw error;
  }
}
