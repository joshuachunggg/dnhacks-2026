import assert from 'node:assert/strict';
import test from 'node:test';

import {
  RealtimeSessionConfigurationError,
  RealtimeSessionUpstreamError,
  RealtimeSessionUnauthorizedError,
  SupportedConsumerCapabilitySchema,
  buildRealtimeSessionInstructions,
  mintRealtimeClientSecret,
} from './realtime-session';

const env = {
  OPENAI_API_KEY: 'sk-test-key',
  REALTIME_DEMO_TOKEN: 'demo-token',
};

const validInput = {
  assessmentId: 'assessment-123',
  demoToken: 'demo-token',
  assessmentContext: {
    propertyAddress: '123 Demo Street, Austin, TX',
    vehicleIntent: '2025 EV',
    chargingIntent: 'Hardwired home charging',
  },
};

test('mints a constrained Realtime client secret with the expected upstream payload', async () => {
  let requestedURL = '';
  let requestedInit: RequestInit | undefined;
  const result = await mintRealtimeClientSecret(validInput, env, async (url, init) => {
    requestedURL = String(url);
    requestedInit = init;
    return Response.json({
      value: 'ek_test_123',
      expires_at: 1_789_000_000,
      session: { id: 'sess_123' },
    });
  });

  assert.equal(requestedURL, 'https://api.openai.com/v1/realtime/client_secrets');
  assert.equal((requestedInit?.headers as Record<string, string>).Authorization, 'Bearer sk-test-key');
  assert.match((requestedInit?.headers as Record<string, string>)['OpenAI-Safety-Identifier'], /^[a-f0-9]{64}$/);
  assert.deepEqual(JSON.parse(String(requestedInit?.body)), {
    session: {
      type: 'realtime',
      model: 'gpt-realtime-2.1-mini',
      audio: {
        output: {
          voice: 'marin',
        },
      },
      instructions: buildRealtimeSessionInstructions(validInput.assessmentContext),
      tools: [{
        type: 'function',
        name: 'request_evidence_photo',
        description: 'Requests one user-captured evidence image when visual confirmation is necessary for the Level 2 EV charger assessment.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {
            evidenceKind: {
              type: 'string',
              enum: ['electrical_panel', 'charger_location', 'route_obstacle', 'equipment_nameplate'],
            },
            reason: { type: 'string' },
          },
          required: ['evidenceKind', 'reason'],
        },
      }, {
        type: 'function',
        name: 'activate_level_2_ev_charger_assessment',
        description: 'Activates the typed Level 2 EV charger assessment interface after the user makes a supported request.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {},
          required: [],
        },
      }, {
        type: 'function',
        name: 'highlight_spatial_reference',
        description: 'Highlights one model-relative area so the user and guide can confirm they mean the same part of the scanned room.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {
            reference: { type: 'string', enum: ['north', 'east', 'south', 'west', 'center'] },
            label: { type: 'string' },
          },
          required: ['reference', 'label'],
        },
      }, {
        type: 'function',
        name: 'request_spatial_placement',
        description: 'Puts the phone into an explicit tap-to-place mode for a user-selected point in the scanned RoomPlan model. The result is a proposed spatial reference, never an engineering finding.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {
            kind: { type: 'string', enum: ['electrical_panel', 'evse', 'route_point'] },
            label: { type: 'string' },
            instruction: { type: 'string' },
          },
          required: ['kind', 'label', 'instruction'],
        },
      }, {
        type: 'function',
        name: 'check_mechanical_assessment_gate',
        description: 'Checks evidence-backed mechanical facts and runs the deterministic assessment only after they are complete.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {},
          required: [],
        },
      }],
      tool_choice: 'auto',
    },
  });
  assert.deepEqual(result, {
    clientSecret: 'ek_test_123',
    expiresAt: 1_789_000_000,
    sessionId: 'sess_123',
  });
});

test('limits the open-ended guide to the typed Level 2 EV charger capability', async () => {
  let requestedInit: RequestInit | undefined;
  await mintRealtimeClientSecret(validInput, env, async (_url, init) => {
    requestedInit = init;
    return Response.json({
      value: 'ek_test_123',
      expires_at: 1_789_000_000,
      session: { id: 'sess_123' },
    });
  });

  assert.deepEqual(SupportedConsumerCapabilitySchema.options, ['level_2_ev_charger']);
  const instructions = JSON.parse(String(requestedInit?.body)).session.instructions as string;
  assert.match(instructions, /open-ended conversational guide/i);
  assert.match(instructions, /Level 2 EV charger/i);
  assert.match(instructions, /Tesla Powerwall 3/i);
  assert.match(instructions, /not equipped to help with that yet/i);
});

test('requires an actionable EV charger interview and panel evidence request', async () => {
  let requestedInit: RequestInit | undefined;
  await mintRealtimeClientSecret(validInput, env, async (_url, init) => {
    requestedInit = init;
    return Response.json({ value: 'ek_test_123', expires_at: 1_789_000_000, session: { id: 'sess_123' } });
  });

  const instructions = JSON.parse(String(requestedInit?.body)).session.instructions as string;
  assert.match(instructions, /every response.*specific action/i);
  assert.match(instructions, /finish and review/i);
  assert.match(instructions, /electrical-panel photo.*final action/i);
  assert.match(instructions, /charger location.*route/i);
  assert.match(instructions, /model-relative reference/i);
});

test('includes typed assessment context so the guide does not ask for the known address again', async () => {
  let requestedInit: RequestInit | undefined;
  await mintRealtimeClientSecret(validInput, env, async (_url, init) => {
    requestedInit = init;
    return Response.json({
      value: 'ek_test_123',
      expires_at: 1_789_000_000,
      session: { id: 'sess_123' },
    });
  });

  const instructions = JSON.parse(String(requestedInit?.body)).session.instructions as string;
  assert.match(instructions, /123 Demo Street, Austin, TX/);
  assert.match(instructions, /Do not ask the user to repeat a known fact/);
  assert.match(instructions, /2025 EV/);
  assert.match(instructions, /Hardwired home charging/);
});

test('exposes only typed native tools to the EV charger guide', async () => {
  let requestedInit: RequestInit | undefined;
  await mintRealtimeClientSecret(validInput, env, async (_url, init) => {
    requestedInit = init;
    return Response.json({ value: 'ek_test_123', expires_at: 1_789_000_000, session: { id: 'sess_123' } });
  });

  const session = JSON.parse(String(requestedInit?.body)).session;
  assert.equal(session.tool_choice, 'auto');
  assert.deepEqual(session.tools[0].parameters.properties.evidenceKind.enum, [
    'electrical_panel',
    'charger_location',
    'route_obstacle',
    'equipment_nameplate',
  ]);
  assert.equal(session.tools[1].name, 'activate_level_2_ev_charger_assessment');
  assert.equal(session.tools[2].name, 'highlight_spatial_reference');
  assert.equal(session.tools[3].name, 'request_spatial_placement');
  assert.deepEqual(session.tools[3].parameters.properties.kind.enum, ['electrical_panel', 'evse', 'route_point']);
  assert.equal(session.tools[4].name, 'check_mechanical_assessment_gate');
});

test('rejects an invalid demo token without contacting OpenAI', async () => {
  await assert.rejects(
    mintRealtimeClientSecret({ ...validInput, demoToken: 'wrong-token' }, env, async () => {
      throw new Error('must not call OpenAI');
    }),
    RealtimeSessionUnauthorizedError,
  );
});

test('rejects missing server configuration without contacting OpenAI', async () => {
  await assert.rejects(
    mintRealtimeClientSecret(validInput, { OPENAI_API_KEY: 'sk-test-key' }, async () => {
      throw new Error('must not call OpenAI');
    }),
    RealtimeSessionConfigurationError,
  );
});

test('preserves an upstream Realtime status without exposing its response body', async () => {
  await assert.rejects(
    mintRealtimeClientSecret(validInput, env, async () => new Response('sensitive upstream response', { status: 403 })),
    (error: unknown) => error instanceof RealtimeSessionUpstreamError && error.statusCode === 403,
  );
});
