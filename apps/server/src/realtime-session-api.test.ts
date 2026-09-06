import assert from 'node:assert/strict';
import test from 'node:test';

import { POST } from '../../../src/app/api/realtime/session/route';

test('POST /api/realtime/session rejects malformed JSON before attempting a mint', async () => {
  const response = await POST(new Request('http://localhost/api/realtime/session', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{',
  }));

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'invalid_json');
});
