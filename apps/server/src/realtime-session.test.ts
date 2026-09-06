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
    assessmentFocus: 'level_2_ev_charger' as const,
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
        name: 'record_panel_fact',
        description: 'Persists one panel fact the user has explicitly identified as known or as a planning approximation, linked to the requested panel image.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {
            field: { type: 'string', enum: ['service_amps', 'bus_rating_amps', 'spare_breaker_spaces'] },
            value: { type: 'integer', minimum: 0 },
            certainty: { type: 'string', enum: ['known', 'approximation'] },
          },
          required: ['field', 'value', 'certainty'],
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
        name: 'activate_adjacent_room_expansion_assessment',
        description: 'Activates the conceptual adjacent-room expansion review after the user asks how two scanned rooms could be opened into one larger room.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {},
          required: [],
        },
      }, {
        type: 'function',
        name: 'record_room_expansion_inputs',
        description: 'Records the three typed adjacent-room expansion inputs and returns the deterministic conceptual option to show.',
        parameters: {
          type: 'object',
          additionalProperties: false,
          properties: {
            sharedWallUtilities: { type: 'string', enum: ['yes', 'no', 'unknown'] },
            exteriorExpansionPossible: { type: 'boolean' },
            loadBearingKnowledge: { type: 'string', enum: ['yes', 'no', 'unknown'] },
          },
          required: ['sharedWallUtilities', 'exteriorExpansionPossible', 'loadBearingKnowledge'],
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
            kind: { type: 'string', enum: ['electrical_panel', 'evse', 'route_point', 'candidate_opening'] },
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

  assert.deepEqual(SupportedConsumerCapabilitySchema.options, ['level_2_ev_charger', 'adjacent_room_expansion']);
  const instructions = JSON.parse(String(requestedInit?.body)).session.instructions as string;
  assert.match(instructions, /open-ended conversational guide/i);
  assert.match(instructions, /Keep spoken replies concise/i);
  assert.match(instructions, /fewest words that preserve the required safety boundary and next action/i);
  assert.match(instructions, /End every spoken response with exactly one explicit user action/i);
  assert.match(instructions, /Never wait for the user to ask for an available result, visual, or next step/i);
  assert.match(instructions, /Never say “we can move onto the next step,” “when you are ready,” or equivalent without naming that action/i);
  assert.match(instructions, /say the exact visible control or physical action first, then call its matching typed tool in that same response/i);
  assert.match(instructions, /The tool call will reveal the action only after your audio completes/i);
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
  assert.match(instructions, /immediately requires the first electrical-panel photo.*do not ask the user whether they are ready first/i);
  assert.match(instructions, /electrical_panel model placement before.*evse placement/i);
  assert.match(instructions, /desired charger area.*panel-to-charger route/i);
  assert.match(instructions, /Do not request a charger-location, route-obstacle, or equipment-nameplate photo/i);
  assert.match(instructions, /tap in the room model/i);
  assert.match(instructions, /model-relative reference/i);
  assert.match(instructions, /North is \+X, East is \+Z/i);
  assert.match(instructions, /make the matching request_evidence_photo or request_spatial_placement tool call in that same response, after the spoken instruction/i);
  assert.match(instructions, /When the user supplies or confirms a numeric value, immediately call record_panel_fact in that same response with certainty known/i);
  assert.match(instructions, /do not ask a separate confirmation or certainty question/i);
  assert.match(instructions, /Do not narrate scene details such as an open panel door, handwritten labels, colors, or other visual inventory/i);
  assert.match(instructions, /State only whether the information needed for the current step is sufficient/i);
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
  assert.equal(session.tools.find((tool: { name: string }) => tool.name === 'record_panel_fact')?.name, 'record_panel_fact');
  assert.deepEqual(session.tools.find((tool: { name: string }) => tool.name === 'record_panel_fact')?.parameters.properties.certainty.enum, ['known', 'approximation']);
  assert.equal(session.tools.find((tool: { name: string }) => tool.name === 'activate_level_2_ev_charger_assessment')?.name, 'activate_level_2_ev_charger_assessment');
  assert.equal(session.tools.find((tool: { name: string }) => tool.name === 'activate_adjacent_room_expansion_assessment')?.name, 'activate_adjacent_room_expansion_assessment');
  const expansionInputs = session.tools.find((tool: { name: string }) => tool.name === 'record_room_expansion_inputs');
  assert.ok(expansionInputs);
  assert.deepEqual(expansionInputs.parameters.properties.sharedWallUtilities.enum, ['yes', 'no', 'unknown']);
  assert.equal(session.tools.find((tool: { name: string }) => tool.name === 'highlight_spatial_reference')?.name, 'highlight_spatial_reference');
  const placement = session.tools.find((tool: { name: string }) => tool.name === 'request_spatial_placement');
  assert.deepEqual(placement?.parameters.properties.kind.enum, ['electrical_panel', 'evse', 'route_point', 'candidate_opening']);
  assert.equal(session.tools.find((tool: { name: string }) => tool.name === 'check_mechanical_assessment_gate')?.name, 'check_mechanical_assessment_gate');
});

test('supports a conceptual adjacent-room expansion without structural approval claims', async () => {
  let requestedInit: RequestInit | undefined;
  await mintRealtimeClientSecret(validInput, env, async (_url, init) => {
    requestedInit = init;
    return Response.json({ value: 'ek_test_123', expires_at: 1_789_000_000, session: { id: 'sess_123' } });
  });

  const session = JSON.parse(String(requestedInit?.body)).session;
  const tool = session.tools.find((candidate: { name: string }) => candidate.name === 'activate_adjacent_room_expansion_assessment');
  assert.ok(tool, 'the room-expansion activation tool must be present');
  assert.match(session.instructions, /adjacent-room expansion/i);
  assert.match(session.instructions, /three questions, one at a time/i);
  assert.match(session.instructions, /Do not ask the purpose/i);
  assert.match(session.instructions, /never request a photo, nameplate, label/i);
  assert.match(session.instructions, /record_room_expansion_inputs/i);
  assert.match(session.instructions, /conceptual cutaway/i);
  assert.match(session.instructions, /licensed structural professional/i);
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
