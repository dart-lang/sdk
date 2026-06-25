// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

void main() {
  group('DDS Security', () {
    late Process process;
    late DartDevelopmentService dds;

    setUp(() async {
      process = await spawnDartProcess('smoke.dart');
    });

    tearDown(() async {
      await dds.shutdown();
      process.kill();
    });

    test('Host and Origin validation', () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);

      final client = HttpClient();

      // 1. Legitimate GET request to DDS-handled path (should return 404 Not Found, but NOT 403)
      {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        final response = await request.close();
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain();
      }

      // 2. Bad Host Header (should be blocked with 403)
      {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      }

      // 3. Bad Origin Header (should be blocked with 403)
      {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      }

      // 4. WebSocket with bad Host header (should be blocked)
      expect(
        () async => await WebSocket.connect(
          dds.wsUri.toString(),
          headers: {
            HttpHeaders.hostHeader: 'evil.example.com',
          },
        ),
        throwsA(isA<WebSocketException>()),
      );

      // 5. WebSocket with bad Origin header (should be blocked)
      expect(
        () async => await WebSocket.connect(
          dds.wsUri.toString(),
          headers: {
            'Origin': 'http://evil.example.com',
          },
        ),
        throwsA(isA<WebSocketException>()),
      );
    });

    test('Disable Origin Check', () async {
      // Start DDS with origin check disabled
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
        disableServiceOriginCheck: true,
      );
      expect(dds.isRunning, true);

      final client = HttpClient();

      // Bad Host Header (should be ALLOWED -> 404 because DevTools not served, but not 403)
      {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain();
      }

      // Bad Origin Header (should be ALLOWED -> 404)
      {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain();
      }
    });
  });
}
