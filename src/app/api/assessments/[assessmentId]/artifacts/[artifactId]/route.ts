import { createHash, randomUUID } from 'node:crypto';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

import { z } from 'zod';

import { assessmentStore } from '../../../../../../../apps/server/src/assessment-store';

const ArtifactPathSchema = z.object({
  assessmentId: z.string().regex(/^[A-Za-z0-9-]{1,128}$/),
  artifactId: z.string().regex(/^[A-Za-z0-9-]{1,128}$/),
}).strict();

const usdzContentType = 'model/vnd.usdz+zip';
const maxArtifactBytes = 100 * 1024 * 1024;

interface ArtifactRouteContext {
  params: Promise<{ assessmentId: string; artifactId: string }>;
}

function artifactRoot(): string {
  return resolve(/* turbopackIgnore: true */ process.env.SPATIAL_ARTIFACTS_DIR ?? join(process.cwd(), 'data', 'spatial-artifacts'));
}

export async function GET(_request: Request, context: ArtifactRouteContext): Promise<Response> {
  const parsedPath = ArtifactPathSchema.safeParse(await context.params);
  if (!parsedPath.success) {
    return Response.json({ error: 'validation_error', details: parsedPath.error.issues }, { status: 400 });
  }
  const { assessmentId, artifactId } = parsedPath.data;
  let bytes: Buffer;
  try {
    bytes = await readFile(join(/* turbopackIgnore: true */ artifactRoot(), assessmentId, `${artifactId}.usdz`));
  } catch {
    return Response.json({ error: 'artifact_not_found' }, { status: 404 });
  }

  return new Response(new Uint8Array(bytes), {
    headers: {
      'content-type': usdzContentType,
      'content-length': String(bytes.byteLength),
      'x-content-sha256': createHash('sha256').update(bytes).digest('hex'),
    },
  });
}

export async function POST(request: Request, context: ArtifactRouteContext): Promise<Response> {
  const parsedPath = ArtifactPathSchema.safeParse(await context.params);
  if (!parsedPath.success) {
    return Response.json({ error: 'validation_error', details: parsedPath.error.issues }, { status: 400 });
  }
  const { assessmentId, artifactId } = parsedPath.data;

  if (!assessmentStore.get(assessmentId)) {
    return Response.json({ error: 'assessment_not_found' }, { status: 404 });
  }
  if (request.headers.get('content-type')?.split(';', 1)[0] !== usdzContentType) {
    return Response.json({ error: 'unsupported_artifact_content_type' }, { status: 415 });
  }

  const declaredLength = Number(request.headers.get('content-length'));
  if (Number.isFinite(declaredLength) && declaredLength > maxArtifactBytes) {
    return Response.json({ error: 'artifact_too_large' }, { status: 413 });
  }

  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength === 0) {
    return Response.json({ error: 'empty_artifact' }, { status: 400 });
  }
  if (bytes.byteLength > maxArtifactBytes) {
    return Response.json({ error: 'artifact_too_large' }, { status: 413 });
  }

  const directory = join(/* turbopackIgnore: true */ artifactRoot(), assessmentId);
  const destination = join(directory, `${artifactId}.usdz`);
  const temporary = join(directory, `.${artifactId}.${randomUUID()}.upload`);
  try {
    await mkdir(directory, { recursive: true });
    await writeFile(temporary, bytes, { flag: 'wx' });
    await rename(temporary, destination);
  } catch {
    return Response.json({ error: 'artifact_write_failed' }, { status: 500 });
  }

  return Response.json({
    artifact: {
      id: artifactId,
      kind: 'room_usdz',
      uri: `local-mac://artifacts/${assessmentId}/${artifactId}.usdz`,
      contentType: usdzContentType,
      byteLength: bytes.byteLength,
      sha256: createHash('sha256').update(bytes).digest('hex'),
    },
  }, { status: 201 });
}
