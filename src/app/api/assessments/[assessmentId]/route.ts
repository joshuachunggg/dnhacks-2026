import { assessmentStore } from '../../../../../apps/server/src/assessment-store';

interface AssessmentRouteContext {
  params: Promise<{ assessmentId: string }>;
}

export async function GET(_request: Request, context: AssessmentRouteContext): Promise<Response> {
  const { assessmentId } = await context.params;
  const assessment = assessmentStore.get(assessmentId);
  if (!assessment) {
    return Response.json({ error: 'assessment_not_found' }, { status: 404 });
  }

  return Response.json({ assessment });
}