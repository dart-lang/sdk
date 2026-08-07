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

    setUpAll(() async {
      process = await spawnDartProcess('smoke.dart');
    });

    tearDownAll(() async {
      process.kill();
    });

    group('Host and Origin validation (Enabled by default)', () {
      late DartDevelopmentService dds;
      late HttpClient client;

      setUpAll(() async {
        dds = await DartDevelopmentService.startDartDevelopmentService(
          remoteVmServiceUri,
        );
        client = HttpClient();
      });

      tearDownAll(() async {
        await dds.shutdown();
        client.close();
      });

      test(
        'allows legitimate GET request to DDS-handled path (should return 404 '
        'Not Found, but NOT 403)',
        () async {
          final request = await client.getUrl(dds.uri!.resolve('devtools'));
          final response = await request.close();
          expect(response.statusCode, HttpStatus.notFound);
          await response.drain();
        },
      );

      test('forbids GET request with bad Host Header', () async {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      });

      test('forbids GET request with bad Origin Header', () async {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        await response.drain();
      });

      test('forbids WebSocket connection with bad Host header', () async {
        expect(
          () async => await WebSocket.connect(
            dds.wsUri.toString(),
            headers: {
              HttpHeaders.hostHeader: 'evil.example.com',
            },
          ),
          throwsA(isA<WebSocketException>()),
        );
      });

      test('forbids WebSocket connection with bad Origin header', () async {
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
    });

    group('Disable Origin Check', () {
      late DartDevelopmentService dds;
      late HttpClient client;

      setUpAll(() async {
        dds = await DartDevelopmentService.startDartDevelopmentService(
          remoteVmServiceUri,
          disableServiceOriginCheck: true,
        );
        client = HttpClient();
      });

      tearDownAll(() async {
        await dds.shutdown();
        client.close();
      });

      test(
        'allows bad Host Header (should be ALLOWED -> 404 because DevTools not '
        'served, but not 403)',
        () async {
          final request = await client.getUrl(dds.uri!.resolve('devtools'));
          request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.notFound);
          await response.drain();
        },
      );

      test('allows bad Origin Header', () async {
        final request = await client.getUrl(dds.uri!.resolve('devtools'));
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain();
      });
    });
  });
}
