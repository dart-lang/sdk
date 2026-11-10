// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'utils/server_driver.dart';

void main() {
  group('DevTools Server Security', () {
    group('Host and Origin validation (Enabled by default)', () {
      late DevToolsServerDriver server;
      late Uri serverUri;
      late HttpClient client;

      setUpAll(() async {
        server = await DevToolsServerDriver.create();
        final event = (await server.stdout.firstWhere(
          (map) => map!['event'] == 'server.started',
        ))!;
        final port = event['params']['port'] as int;
        serverUri = Uri.parse('http://127.0.0.1:$port/');
        client = HttpClient();
      });

      tearDownAll(() async {
        client.close();
        server.kill();
      });

      test('allows legitimate GET request to /api/ping', () async {
        final request = await client.getUrl(serverUri.resolve('api/ping'));
        final response = await request.close();
        expect(response.statusCode, HttpStatus.ok);
        await response.drain();
      });

      test('forbids GET request with bad Host Header to /api/ping', () async {
        final request = await client.getUrl(serverUri.resolve('api/ping'));
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      });

      test('forbids GET request with bad Origin Header to /api/sse', () async {
        final request = await client.getUrl(serverUri.resolve('api/sse'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      });

      // Regression test: the Origin check used to be applied only to
      // `/api/sse`. Every other `api/*` method (ping, and the ServerApi
      // endpoints that perform side effects, such as the deeplink handlers
      // that spawn a `flutter`/`xcodebuild` process for a caller-supplied
      // path) relied solely on the Host header check, which does not stop a
      // same-machine cross-origin request: Host reflects the request's
      // destination, not the page that issued it, so it is always this
      // server's own host/port regardless of who sent the request.
      test('forbids GET request with bad Origin Header to /api/ping', () async {
        final request = await client.getUrl(serverUri.resolve('api/ping'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      });

      for (final (site, status) in [
        ('cross-site', HttpStatus.forbidden),
        ('same-site', HttpStatus.forbidden),
        ('same-origin', HttpStatus.ok),
        ('none', HttpStatus.ok),
      ]) {
        test(
          'returns $status for GET request without Origin and with '
          'Sec-Fetch-Site: $site to /api/ping',
          () async {
            final request = await client.getUrl(serverUri.resolve('api/ping'));
            request.headers.set('Sec-Fetch-Site', site);
            final response = await request.close();
            expect(response.statusCode, status);
            await response.drain();
          },
        );
      }

      test(
        'forbids GET request without Origin and with cross-site '
        'Sec-Fetch-Site header to /api/sse',
        () async {
          final request = await client.getUrl(serverUri.resolve('api/sse'));
          request.headers.set('Sec-Fetch-Site', 'cross-site');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.forbidden);
          await response.drain();
        },
      );

      test(
        'allows GET request with loopback Origin and same-site '
        'Sec-Fetch-Site header to /api/ping',
        () async {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          request.headers.set('Origin', 'http://localhost:12345');
          request.headers.set('Sec-Fetch-Site', 'same-site');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.ok);
          await response.drain();
        },
      );
    });

    group('Disable Origin Check', () {
      late DevToolsServerDriver server;
      late Uri serverUri;
      late HttpClient client;

      setUpAll(() async {
        server = await DevToolsServerDriver.create(
          additionalArgs: ['--disable-service-origin-check'],
        );
        final event = (await server.stdout.firstWhere(
          (map) => map!['event'] == 'server.started',
        ))!;
        final port = event['params']['port'] as int;
        serverUri = Uri.parse('http://127.0.0.1:$port/');
        client = HttpClient();
      });

      tearDownAll(() async {
        client.close();
        server.kill();
      });

      test('allows bad Host Header to /api/ping', () async {
        final request = await client.getUrl(serverUri.resolve('api/ping'));
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.ok);
        await response.drain();
      });

      test('allows bad Origin Header to /api/sse', () async {
        final request = await client.getUrl(serverUri.resolve('api/sse'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, isNot(HttpStatus.forbidden));
        await response.drain();
      });

      test('allows bad Origin Header to /api/ping', () async {
        final request = await client.getUrl(serverUri.resolve('api/ping'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, isNot(HttpStatus.forbidden));
        await response.drain();
      });

      test(
        'allows cross-site Sec-Fetch-Site header without Origin to /api/ping',
        () async {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          request.headers.set('Sec-Fetch-Site', 'cross-site');
          final response = await request.close();
          expect(response.statusCode, isNot(HttpStatus.forbidden));
          await response.drain();
        },
      );
    });
  }, timeout: const Timeout.factor(10));
}
