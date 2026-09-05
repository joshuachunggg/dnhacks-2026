import { SiteGraphSchema, SiteGraphVersion } from '../../../packages/schemas/src/sitegraph';
import type { SiteGraphV0 } from '../../../packages/schemas/src/sitegraph';

export type ServerLaneState = 'placeholder';

export interface ServerLaneManifest {
  readonly lane: 'server';
  readonly schemaVersion: typeof SiteGraphVersion;
  readonly state: ServerLaneState;
  readonly schema: typeof SiteGraphSchema;
}

export interface ServerDraftEnvelope {
  readonly schemaVersion: typeof SiteGraphVersion;
  readonly payload: SiteGraphV0 | null;
}

export const serverLaneManifest: ServerLaneManifest = {
  lane: 'server',
  schemaVersion: SiteGraphVersion,
  state: 'placeholder',
  schema: SiteGraphSchema,
};

export function createServerLaneManifest(): ServerLaneManifest {
  return serverLaneManifest;
}

export function createEmptyServerDraft(): ServerDraftEnvelope {
  return {
    schemaVersion: SiteGraphVersion,
    payload: null,
  };
}
