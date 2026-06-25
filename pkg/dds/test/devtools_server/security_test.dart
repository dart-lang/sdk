// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'utils/server_driver.dart';

void main() {
  group('DevTools Server Security', () {
    test('Host and Origin validation (Enabled by default)', () async {
      final server = await DevToolsServerDriver.create();
      try {
        // Wait for server to start and get the port.
        final event = (await server.stdout.firstWhere(
          (map) => map!['event'] == 'server.started',
        ))!;
        final port = event['params']['port'] as int;
        final serverUri = Uri.parse('http://127.0.0.1:$port/');

        final client = HttpClient();

        // 1. Legitimate GET request to /api/ping (should succeed)
        {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          final response = await request.close();
          expect(response.statusCode, HttpStatus.ok);
          await response.drain();
        }

        // 2. Bad Host Header to /api/ping (should be blocked with 403)
        {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.forbidden);
          await response.drain();
        }

        // 3. Bad Origin Header to /api/sse (should be blocked with 403)
        {
          final request = await client.getUrl(serverUri.resolve('api/sse'));
          request.headers.set('Origin', 'http://evil.example.com');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.forbidden);
          await response.drain();
        }

        client.close();
      } finally {
        server.kill();
      }
    }, timeout: const Timeout.factor(10));

    test('Disable Origin Check', () async {
      // Start server with origin check disabled
      final server = await DevToolsServerDriver.create(
        additionalArgs: ['--disable-service-origin-check'],
      );
      try {
        final event = (await server.stdout.firstWhere(
          (map) => map!['event'] == 'server.started',
        ))!;
        final port = event['params']['port'] as int;
        final serverUri = Uri.parse('http://127.0.0.1:$port/');

        final client = HttpClient();

        // Bad Host Header (should be ALLOWED -> 200 OK because checks are disabled)
        {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.ok);
          await response.drain();
        }

        // Bad Origin Header to /api/sse (should be ALLOWED -> not 403, though it might fail with 400/404 because of invalid SSE handshake)
        {
          final request = await client.getUrl(serverUri.resolve('api/sse'));
          request.headers.set('Origin', 'http://evil.example.com');
          final response = await request.close();
          expect(response.statusCode, isNot(HttpStatus.forbidden));
          await response.drain();
        }

        client.close();
      } finally {
        server.kill();
      }
    }, timeout: const Timeout.factor(10));
  });
}
