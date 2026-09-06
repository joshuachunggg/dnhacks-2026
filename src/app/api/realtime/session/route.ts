import { z } from 'zod';

import {
  RealtimeSessionConfigurationError,
  RealtimeSessionUnauthorizedError,
  RealtimeSessionUpstreamError,
  mintRealtimeClientSecret,
} from '../../../../../apps/server/src/realtime-session';

export const runtime = 'nodejs';

export async function POST(request: Request): Promise<Response> {
  let input: unknown;
  try {
    input = await request.json();
  } catch {
    return Response.json({ error: 'invalid_json' }, { status: 400 });
  }

  try {
    const session = await mintRealtimeClientSecret(input);
    return Response.json(session, { status: 201 });
  } catch (error) {
    if (error instanceof RealtimeSessionUnauthorizedError) {
      return Response.json({ error: 'unauthorized' }, { status: 401 });
    }
    if (error instanceof z.ZodError) {
      return Response.json({ error: 'validation_error', details: error.issues }, { status: 400 });
    }
    if (error instanceof RealtimeSessionConfigurationError) {
      return Response.json({ error: 'realtime_not_configured' }, { status: 503 });
    }
    if (error instanceof RealtimeSessionUpstreamError) {
      return Response.json(
        { error: 'realtime_unavailable', upstreamStatus: error.statusCode ?? null },
        { status: 502 },
      );
    }
    throw error;
  }
}
