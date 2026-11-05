// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

import 'utils/utilities.dart';

void main() {
  group('Host and Origin security:', () {
    late DartRuntimeService service;
    late HttpClient client;

    setUp(() async {
      service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(
          enableLogging: true,
          disableAuthCodes: true,
        ),
      );
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('allows requests with loopback Host header', () async {
      final request = await client.getUrl(service.httpUri);
      request.headers.set(HttpHeaders.hostHeader, 'localhost');
      final response = await request.close();
      expect(response.statusCode, isNot(equals(HttpStatus.forbidden)));
      await response.drain<void>();
    });

    test('allows requests with matching Host header', () async {
      final request = await client.getUrl(service.httpUri);
      request.headers.set(
        HttpHeaders.hostHeader,
        '${service.uri.host}:${service.uri.port}',
      );
      final response = await request.close();
      expect(response.statusCode, isNot(equals(HttpStatus.forbidden)));
      await response.drain<void>();
    });

    test('forbids requests with invalid Host header', () async {
      final request = await client.getUrl(service.httpUri);
      request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
      final response = await request.close();
      expect(response.statusCode, equals(HttpStatus.forbidden));
      await response.drain<void>();
    });

    test('allows requests with loopback Origin header', () async {
      final request = await client.getUrl(service.httpUri);
      request.headers.set('Origin', 'http://localhost');
      final response = await request.close();
      expect(response.statusCode, isNot(equals(HttpStatus.forbidden)));
      await response.drain<void>();
    });

    test('allows requests with matching Origin header', () async {
      final request = await client.getUrl(service.httpUri);
      request.headers.set('Origin', service.httpUri.toString());
      final response = await request.close();
      expect(response.statusCode, isNot(equals(HttpStatus.forbidden)));
      await response.drain<void>();
    });

    test('forbids requests with invalid Origin header', () async {
      final request = await client.getUrl(service.httpUri);
      request.headers.set('Origin', 'http://evil.example.com');
      final response = await request.close();
      expect(response.statusCode, equals(HttpStatus.forbidden));
      await response.drain<void>();
    });

    test(
      'allows invalid Host and Origin when origin checks are disabled',
      () async {
        final noCheckService = await createDartRuntimeServiceForTest(
          config: const DartRuntimeServiceOptions(
            enableLogging: true,
            disableAuthCodes: true,
            disableOriginCheck: true,
          ),
        );

        final request = await client.getUrl(noCheckService.httpUri);
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        request.headers.set('Origin', 'http://evil.example.com');
        final response = await request.close();
        expect(response.statusCode, isNot(equals(HttpStatus.forbidden)));
        await response.drain<void>();
      },
    );
  });
}
