import { z } from 'zod';

import { assessmentStore } from '../../../../apps/server/src/assessment-store';

function validationErrorResponse(error: z.ZodError): Response {
  return Response.json(
    {
      error: 'validation_error',
      details: error.issues,
    },
    { status: 400 },
  );
}

export async function POST(request: Request): Promise<Response> {
  let input: unknown;
  try {
    input = await request.json();
  } catch {
    return Response.json({ error: 'invalid_json' }, { status: 400 });
  }

  try {
    const assessment = assessmentStore.create(input);
    return Response.json({ assessment }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return validationErrorResponse(error);
    }
    throw error;
  }
}
