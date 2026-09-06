import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { POST as createAssessment } from '../../../src/app/api/assessments/route';
import { POST as appendEvent } from '../../../src/app/api/assessments/[assessmentId]/events/route';
import { GET, POST } from '../../../src/app/api/assessments/[assessmentId]/artifacts/[artifactId]/route';
import { SiteGraphVersion } from '../../../packages/schemas/src/sitegraph';

const assessmentId = 'assessment-local-artifact-test';
const artifactId = 'capture-roomplan-local-artifact-test';
const usdzBytes = new TextEncoder().encode('minimal local usdz test payload');

function context() {
  return { params: Promise.resolve({ assessmentId, artifactId }) };
}

function assessmentFixture() {
  return {
    schemaVersion: SiteGraphVersion,
    assessmentId,
    evidence: [],
    spatialCaptures: [],
    visualFrames: [],
    spatialObjects: [],
    site: {
      id: 'site-local-artifact-test',
      label: 'Local artifact test',
      address: '123 Test Street',
      jurisdiction: { city: 'Austin', county: 'Travis', state: 'TX', ahj: 'City of Austin' },
    },
    proposedEvseLocation: {
      id: 'evse-local-artifact-test', label: 'Unknown', wall: 'unknown', status: 'proposed', sourceType: 'assumed', evidenceIds: [], timestamp: '2026-09-06T00:00:00.000Z', producer: 'test', assumptions: [], notes: [],
    },
    electricalPanel: {
      id: 'panel-local-artifact-test', label: 'Unknown', status: 'proposed', sourceType: 'assumed', evidenceIds: [], timestamp: '2026-09-06T00:00:00.000Z', producer: 'test', visibleConditionNotes: [], assumptions: [], notes: [],
    },
    measurements: [], observations: [], engineeringScenarios: [], toolRuns: [], costScenarios: [],
    finalAssessment: {
      status: 'insufficient_data', summary: 'Test assessment', unresolvedRequirements: [], professionalVerificationItems: [], installerHandoff: { title: 'Test', bullets: [] }, timestamp: '2026-09-06T00:00:00.000Z',
    },
  };
}

test('POST /api/assessments/:id/artifacts/:artifactId stores a verified USDZ on the local Mac', async () => {
  const storageRoot = await mkdtemp(join(tmpdir(), 'sitegraph-artifacts-'));
  process.env.SPATIAL_ARTIFACTS_DIR = storageRoot;
  try {
    assert.equal((await createAssessment(new Request('http://localhost/api/assessments', {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(assessmentFixture()),
    }))).status, 201);

    const response = await POST(new Request(`http://localhost/api/assessments/${assessmentId}/artifacts/${artifactId}`, {
      method: 'POST',
      headers: { 'content-type': 'model/vnd.usdz+zip' },
      body: usdzBytes,
    }), context());

    assert.equal(response.status, 201);
    const body = await response.json();
    assert.deepEqual(body.artifact, {
      id: artifactId,
      kind: 'room_usdz',
      uri: `local-mac://artifacts/${assessmentId}/${artifactId}.usdz`,
      contentType: 'model/vnd.usdz+zip',
      byteLength: usdzBytes.byteLength,
      sha256: '46cbb9d6cfcafc1a764a31ce1b66e69699fe3dd391fb44ef38863db197f6f648',
    });
    assert.deepEqual(
      await readFile(join(storageRoot, assessmentId, `${artifactId}.usdz`)),
      Buffer.from(usdzBytes),
    );

    const eventResponse = await appendEvent(new Request(`http://localhost/api/assessments/${assessmentId}/events`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        eventId: 'event-roomplan-local-artifact-test',
        eventName: 'spatial.capture.recorded',
        timestamp: '2026-09-06T00:00:00.000Z',
        producer: 'ios-roomplan',
        schemaVersion: SiteGraphVersion,
        payload: {
          id: 'capture-local-artifact-test',
          kind: 'roomplan_room',
          status: 'confirmed',
          coordinateSpaceId: 'roomplan-local-artifact-test',
          timestamp: '2026-09-06T00:00:00.000Z',
          producer: 'ios-roomplan',
          detectedObjectTypes: [],
          artifacts: [body.artifact],
          evidence: [{
            id: 'evidence-roomplan-local-artifact-test',
            type: 'room_model',
            label: 'Local Mac RoomPlan capture',
            uri: body.artifact.uri,
          }],
        },
      }),
    }), { params: Promise.resolve({ assessmentId }) });
    assert.equal(eventResponse.status, 200);
    assert.equal((await eventResponse.json()).assessment.spatialCaptures[0].artifacts[0].uri, body.artifact.uri);
  } finally {
    delete process.env.SPATIAL_ARTIFACTS_DIR;
    await rm(storageRoot, { recursive: true, force: true });
  }
});

test('GET /api/assessments/:id/artifacts/:artifactId restores the verified USDZ from the local Mac', async () => {
  const storageRoot = await mkdtemp(join(tmpdir(), 'sitegraph-artifacts-'));
  process.env.SPATIAL_ARTIFACTS_DIR = storageRoot;
  try {
    assert.equal((await createAssessment(new Request('http://localhost/api/assessments', {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(assessmentFixture()),
    }))).status, 201);
    assert.equal((await POST(new Request(`http://localhost/api/assessments/${assessmentId}/artifacts/${artifactId}`, {
      method: 'POST', headers: { 'content-type': 'model/vnd.usdz+zip' }, body: usdzBytes,
    }), context())).status, 201);

    const response = await GET(new Request(`http://localhost/api/assessments/${assessmentId}/artifacts/${artifactId}`), context());

    assert.equal(response.status, 200);
    assert.equal(response.headers.get('content-type'), 'model/vnd.usdz+zip');
    assert.equal(response.headers.get('content-length'), String(usdzBytes.byteLength));
    assert.equal(response.headers.get('x-content-sha256'), '46cbb9d6cfcafc1a764a31ce1b66e69699fe3dd391fb44ef38863db197f6f648');
    assert.deepEqual(new Uint8Array(await response.arrayBuffer()), usdzBytes);
  } finally {
    delete process.env.SPATIAL_ARTIFACTS_DIR;
    await rm(storageRoot, { recursive: true, force: true });
  }
});

test('POST /api/assessments/:id/artifacts/:artifactId rejects an unknown assessment without writing a file', async () => {
  const storageRoot = await mkdtemp(join(tmpdir(), 'sitegraph-artifacts-'));
  process.env.SPATIAL_ARTIFACTS_DIR = storageRoot;
  try {
    const response = await POST(new Request('http://localhost/api/assessments/missing/artifacts/capture-roomplan-missing', {
      method: 'POST', headers: { 'content-type': 'model/vnd.usdz+zip' }, body: usdzBytes,
    }), { params: Promise.resolve({ assessmentId: 'missing', artifactId: 'capture-roomplan-missing' }) });
    assert.equal(response.status, 404);
  } finally {
    delete process.env.SPATIAL_ARTIFACTS_DIR;
    await rm(storageRoot, { recursive: true, force: true });
  }
});
