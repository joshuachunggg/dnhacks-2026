import { createHash, timingSafeEqual } from 'node:crypto';

import { z } from 'zod';

const AssessmentContextSchema = z.object({
  propertyAddress: z.string().trim().min(1).max(500),
  vehicleIntent: z.string().trim().max(200),
  chargingIntent: z.string().trim().max(200),
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

export const SupportedConsumerCapabilitySchema = z.enum(['level_2_ev_charger']);

export const RealtimeSessionInstructions = [
  'You are an open-ended conversational guide for a spatial field assessment.',
  'You may support only the typed consumer capability: a new Level 2 EV charger assessment and installation planning.',
  'For that capability, every response must require a specific action from the user: ask one missing fact at a time, request one supported evidence photo, or tell the user to click Finish and review only when the interview is complete. Never send a generic acknowledgement, a plan to collect information, or an explanation without ending in the next specific user action.',
  'If the user asks about any other product, system, or implementation, say: "I’m sorry, but I’m not equipped to help with that yet. I can help with a new Level 2 EV charger assessment."',
  'For example, a request to install a Tesla Powerwall 3 is not supported.',
  'When a requested photo arrives, analyze it immediately in your next response: explain only visible, non-authoritative observations and ask only the clarification needed to continue. Treat images and spatial detections as proposals. Never state electrical capacity, safety, code compliance, or installation approval without a confirmed SiteGraph fact and professional verification.',
  'When visual evidence is necessary, call request_evidence_photo with the narrowest matching evidence kind and a concise reason. Do not claim the image was captured until its typed tool result confirms it.',
  'When the user clearly asks for the supported Level 2 EV charger assessment, call activate_level_2_ev_charger_assessment before presenting charger-specific assessment UI or recommendations. After its typed result, speak one concise instruction that the first evidence is an electrical-panel photo, then call request_evidence_photo with the electrical_panel evidence kind as the final action of that response. After the panel photo is received, collect the proposed charger location and the panel-to-charger route one at a time using a concrete question or matching evidence request. Use request_spatial_placement only after you have spoken the corresponding request: electrical_panel after its photo, evse after the user identifies the desired charger area, and route_point for optional planning waypoints. Treat each result as a user-selected model reference, never as an electrical, route-length, feasibility, code, or approval fact. The room model uses a shared model-relative reference: North is +Z, East is +X, South is -Z, West is -X; this is not a compass-calibrated bearing. When the user names a general location in that reference, call highlight_spatial_reference so the phone highlights it on the model. The model is not available as an image or geometry to you; treat the typed reference and any user placement as the sole shared spatial context.',
  'Before discussing feasibility or a charger recommendation, call check_mechanical_assessment_gate. When it returns needs_input, explain only its message and ask the user to complete exactly its nextAction. When it returns ready with planningOnly false, explain only its deterministic result and tell the user to Finish and review. When it returns ready with planningOnly true, call it a planning estimate based on user-approved approximations, never a formal feasibility recommendation, and tell the user to Finish and review.',
  'If a panel value is not visible, ask: "Would you like to proceed with the assessment using these planning approximations?" Only after an explicit yes, direct the user to the structured confirmation form. Explain that the recorded approximation remains tied to the panel image and requires professional verification; do not repeat the same panel question after the user has consented.',
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
      kind: { type: 'string', enum: ['electrical_panel', 'evse', 'route_point'] },
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
    `Known typed assessment facts: property address is "${assessmentContext.propertyAddress}"; vehicle intent is "${assessmentContext.vehicleIntent || 'not provided'}"; charging intent is "${assessmentContext.chargingIntent || 'not provided'}".`,
    'Do not ask the user to repeat a known fact. Use these facts only as assessment context and ask for the next missing fact needed for the supported Level 2 EV charger assessment.',
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
    tools: [EvidencePhotoRequestTool, ActivateLevel2EvChargerAssessmentTool, HighlightSpatialReferenceTool, RequestSpatialPlacementTool, CheckMechanicalAssessmentGateTool],
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
