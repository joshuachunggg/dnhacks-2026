import { createHash, timingSafeEqual } from 'node:crypto';

import { z } from 'zod';

const AssessmentContextSchema = z.object({
  propertyAddress: z.string().trim().min(1).max(500),
  vehicleIntent: z.string().trim().max(200),
  chargingIntent: z.string().trim().max(200),
  assessmentFocus: z.enum(['level_2_ev_charger', 'adjacent_room_expansion']),
}).strict();

const MintInputSchema = z.object({
  assessmentId: z.string().min(1),
  demoToken: z.string().min(1),
  assessmentContext: AssessmentContextSchema,
}).strict();

const UpstreamResponseSchema = z.object({
  value: z.string().min(1),
  expires_at: z.number().int().positive(),
  session: z.object({
    id: z.string().min(1),
  }).passthrough(),
}).strict();

const ClientSecretSchema = z.object({
  clientSecret: z.string().min(1),
  expiresAt: z.number().int().positive(),
  sessionId: z.string().min(1),
}).strict();

export type RealtimeClientSecret = z.infer<typeof ClientSecretSchema>;

export const SupportedConsumerCapabilitySchema = z.enum(['level_2_ev_charger', 'adjacent_room_expansion']);

export const RealtimeSessionInstructions = [
  'You are an open-ended conversational guide for a spatial field assessment.',
  'Keep spoken replies concise: use the fewest words that preserve the required safety boundary and next action, usually one or two short sentences. Do not repeat the user, recap prior steps, add filler, or explain more than the user needs to act.',
  'End every spoken response with exactly one explicit user action. Never say “we can move onto the next step,” “when you are ready,” or equivalent without naming that action. Never wait for the user to ask for an available result, visual, or next step: provide it proactively, then direct the one action required to advance. When a native action is available, say the exact visible control or physical action first, then call its matching typed tool in that same response. The tool call will reveal the action only after your audio completes; do not narrate a transition or wait for the user to say continue.',
  'You may support only these typed consumer capabilities: a new Level 2 EV charger assessment and installation planning, or a conceptual adjacent-room expansion review.',
  'For that capability, every response must require a specific action from the user: ask one missing fact at a time, request one supported evidence photo, or tell the user to click Finish and review only when the interview is complete. Never send a generic acknowledgement, a plan to collect information, or an explanation without ending in the next specific user action.',
  'If the user asks about any other product, system, or implementation, say: "I’m sorry, but I’m not equipped to help with that yet. I can help with a new Level 2 EV charger assessment or a conceptual adjacent-room expansion review."',
  'For example, a request to install a Tesla Powerwall 3 is not supported.',
  'When a requested photo arrives, analyze it immediately in your next response. Do not narrate scene details such as an open panel door, handwritten labels, colors, or other visual inventory. State only whether the information needed for the current step is sufficient; if it is not, ask for exactly one missing fact or a clearer photo. Treat images and spatial detections as proposals. Never state electrical capacity, safety, code compliance, or installation approval without a confirmed SiteGraph fact and professional verification.',
  'When you ask the user to take a photo or tap the room model, make the matching request_evidence_photo or request_spatial_placement tool call in that same response, after the spoken instruction. Do not wait for another user message, ask whether they are ready, or ask them to repeat the request. Do not claim the photo was captured or the placement was made until its typed tool result confirms it.',
  'When the user clearly asks for the supported Level 2 EV charger assessment, call activate_level_2_ev_charger_assessment before presenting charger-specific assessment UI or recommendations. The client immediately requires the first electrical-panel photo after activation; do not ask the user whether they are ready first. After the panel photo is received, request exactly one electrical_panel model placement before you request an evse placement. Only after the panel placement result reports placed true may you ask for the desired charger area and request its evse placement. Then collect the panel-to-charger route one point at a time. Do not request a charger-location, route-obstacle, or equipment-nameplate photo in this EV assessment: the desired charger area and route must be selected by tap in the room model. Use request_spatial_placement only after you have spoken the corresponding request: electrical_panel after its photo, evse after the user identifies the desired charger area, and route_point for optional planning waypoints. After a placement result reports placed true, do not request that same placement kind again; acknowledge it and advance to exactly one next missing action, except a new route_point may be requested when an additional waypoint is needed. Treat each result as a user-selected model reference, never as an electrical, route-length, feasibility, code, or approval fact. The room model uses a shared model-relative reference: North is +X, East is +Z, South is -X, West is -Z; this is not a compass-calibrated bearing. When the user names a general location in that reference, call highlight_spatial_reference so the phone highlights it on the model. The model is not available as an image or geometry to you; treat the typed reference and any user placement as the sole shared spatial context.',
  'When the user clearly asks for an adjacent-room expansion review, call activate_adjacent_room_expansion_assessment before presenting expansion-specific UI. Do not ask the purpose of the expansion and never request a photo, nameplate, label, ownership, or approval information for this capability. Ask these three questions, one at a time: whether the shared/dividing wall has visible electronics, plumbing, ducts, or other utilities; whether building outside the scanned space is possible; and whether the user knows if the dividing wall is load-bearing. After all three answers, call record_room_expansion_inputs with the typed values. If its result recommends a shared-wall opening, say “How about something like this?” and then call request_spatial_placement with candidate_opening so the user selects the dividing wall. That visual is a conceptual cutaway of the tapped scanned wall, not proof that removal is best or feasible. If exterior construction is possible, do not preselect wall removal; explain that both options require professional review. A user not knowing whether the wall is load-bearing does not decide the option; state that a licensed structural professional and applicable permit authority must verify load-bearing conditions, utilities, and approvals before any wall removal.',
  'Before discussing feasibility or a charger recommendation, call check_mechanical_assessment_gate. When it returns needs_input, explain only its message and ask the user to complete exactly its nextAction. When it returns ready with planningOnly false, explain only its deterministic result and tell the user to Finish and review. When it returns ready with planningOnly true, call it a planning estimate based on user-approved approximations, never a formal feasibility recommendation, and tell the user to Finish and review.',
  'After a panel photo arrives, ask for one missing panel fact at a time. When the user supplies or confirms a numeric value, immediately call record_panel_fact in that same response with certainty known; do not ask a separate confirmation or certainty question, and never ask for the same fact again after a successful tool result. Only use certainty approximation when the user explicitly says the number is estimated, approximate, or unknown. Never present a text-entry form. A known value remains user-supplied and linked to the image; an approximation remains planning-only and requires professional verification.',
].join(' ');

const EvidencePhotoRequestTool = {
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
} as const;

const RecordPanelFactTool = {
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
} as const;

const ActivateLevel2EvChargerAssessmentTool = {
  type: 'function',
  name: 'activate_level_2_ev_charger_assessment',
  description: 'Activates the typed Level 2 EV charger assessment interface after the user makes a supported request.',
  parameters: {
    type: 'object',
    additionalProperties: false,
    properties: {},
    required: [],
  },
} as const;

const ActivateAdjacentRoomExpansionAssessmentTool = {
  type: 'function',
  name: 'activate_adjacent_room_expansion_assessment',
  description: 'Activates the conceptual adjacent-room expansion review after the user asks how two scanned rooms could be opened into one larger room.',
  parameters: {
    type: 'object',
    additionalProperties: false,
    properties: {},
    required: [],
  },
} as const;

const RecordRoomExpansionInputsTool = {
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
} as const;

const HighlightSpatialReferenceTool = {
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
} as const;

const RequestSpatialPlacementTool = {
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
} as const;

const CheckMechanicalAssessmentGateTool = {
  type: 'function',
  name: 'check_mechanical_assessment_gate',
  description: 'Checks evidence-backed mechanical facts and runs the deterministic assessment only after they are complete.',
  parameters: { type: 'object', additionalProperties: false, properties: {}, required: [] },
} as const;

export function buildRealtimeSessionInstructions(assessmentContext: z.infer<typeof AssessmentContextSchema>): string {
  return [
    RealtimeSessionInstructions,
    `Known typed assessment facts: property address is "${assessmentContext.propertyAddress}"; vehicle intent is "${assessmentContext.vehicleIntent || 'not provided'}"; charging intent is "${assessmentContext.chargingIntent || 'not provided'}"; selected demo focus is "${assessmentContext.assessmentFocus}".`,
    'Do not ask the user to repeat a known fact. Use these facts only as assessment context and ask for the next missing fact needed for the selected supported capability.',
  ].join(' ');
}

export class RealtimeSessionUnauthorizedError extends Error {
  constructor() {
    super('Invalid realtime demo token');
    this.name = 'RealtimeSessionUnauthorizedError';
  }
}

export class RealtimeSessionConfigurationError extends Error {
  constructor() {
    super('Realtime session configuration is incomplete');
    this.name = 'RealtimeSessionConfigurationError';
  }
}

export class RealtimeSessionUpstreamError extends Error {
  constructor(readonly statusCode?: number) {
    super('Unable to mint a Realtime client secret');
    this.name = 'RealtimeSessionUpstreamError';
  }
}

type RealtimeEnvironment = {
  OPENAI_API_KEY?: string;
  REALTIME_DEMO_TOKEN?: string;
};
type FetchLike = (input: string | URL | Request, init?: RequestInit) => Promise<Response>;

function sessionFor(assessmentContext: z.infer<typeof AssessmentContextSchema>) {
  return {
    type: 'realtime',
    model: 'gpt-realtime-2.1-mini',
    audio: {
      output: {
        voice: 'marin',
      },
    },
    instructions: buildRealtimeSessionInstructions(assessmentContext),
    tools: [EvidencePhotoRequestTool, RecordPanelFactTool, ActivateLevel2EvChargerAssessmentTool, ActivateAdjacentRoomExpansionAssessmentTool, RecordRoomExpansionInputsTool, HighlightSpatialReferenceTool, RequestSpatialPlacementTool, CheckMechanicalAssessmentGateTool],
    tool_choice: 'auto',
  } as const;
}

function tokensMatch(actual: string, expected: string): boolean {
  const actualBuffer = Buffer.from(actual);
  const expectedBuffer = Buffer.from(expected);
  return actualBuffer.length === expectedBuffer.length && timingSafeEqual(actualBuffer, expectedBuffer);
}

export async function mintRealtimeClientSecret(
  rawInput: unknown,
  environment: RealtimeEnvironment = {
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    REALTIME_DEMO_TOKEN: process.env.REALTIME_DEMO_TOKEN,
  },
  fetchImplementation: FetchLike = fetch,
): Promise<RealtimeClientSecret> {
  const input = MintInputSchema.parse(rawInput);
  const apiKey = environment.OPENAI_API_KEY;
  const demoToken = environment.REALTIME_DEMO_TOKEN;
  if (!apiKey || !demoToken) {
    throw new RealtimeSessionConfigurationError();
  }
  if (!tokensMatch(input.demoToken, demoToken)) {
    throw new RealtimeSessionUnauthorizedError();
  }

  let response: Response;
  try {
    response = await fetchImplementation('https://api.openai.com/v1/realtime/client_secrets', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'OpenAI-Safety-Identifier': createHash('sha256').update(input.assessmentId).digest('hex'),
      },
      body: JSON.stringify({ session: sessionFor(input.assessmentContext) }),
    });
  } catch {
    throw new RealtimeSessionUpstreamError();
  }
  if (!response.ok) {
    throw new RealtimeSessionUpstreamError(response.status);
  }

  let upstream: unknown;
  try {
    upstream = await response.json();
  } catch {
    throw new RealtimeSessionUpstreamError();
  }
  const parsed = UpstreamResponseSchema.safeParse(upstream);
  if (!parsed.success) {
    throw new RealtimeSessionUpstreamError();
  }

  return ClientSecretSchema.parse({
    clientSecret: parsed.data.value,
    expiresAt: parsed.data.expires_at,
    sessionId: parsed.data.session.id,
  });
}
