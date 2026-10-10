// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// The server address the handler is told to trust.
final serverUri = Uri(scheme: 'http', host: 'localhost', port: 9100);

Request apiRequest({String? host = 'localhost:9100', String? origin}) {
  return Request(
    'GET',
    serverUri.resolve('api/ping'),
    headers: {
      if (host != null) HttpHeaders.hostHeader: host,
      if (origin != null) 'Origin': origin,
    },
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drs_handler_security');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Handler> buildHandler({bool disableOriginCheck = false}) async {
    return await defaultHandler(
      buildDir: tempDir.path,
      devtoolsExtensionsManager: ExtensionsManager(),
      serverUri: serverUri,
      disableOriginCheck: disableOriginCheck,
    );
  }

  group('api/* origin and host checks enabled by default', () {
    test('allows a legitimate request with no Origin header', () async {
      final handler = await buildHandler();
      final response = await handler(apiRequest());
      expect(response.statusCode, HttpStatus.ok);
    });

    test('allows a same-origin browser request', () async {
      final handler = await buildHandler();
      final response = await handler(
        apiRequest(origin: 'http://localhost:9100'),
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('allows a loopback origin on another port', () async {
      // Necessary for adb port forwarding.
      final handler = await buildHandler();
      final response = await handler(
        apiRequest(origin: 'http://127.0.0.1:1234'),
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('forbids a cross-origin request to api/ping', () async {
      final handler = await buildHandler();
      final response = await handler(
        apiRequest(origin: 'https://evil.example.com'),
      );
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden origin');
    });

    test('forbids a malformed Origin header', () async {
      final handler = await buildHandler();
      final response = await handler(apiRequest(origin: 'http://[[['));
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden origin');
    });

    test('forbids a spoofed Host header to api/ping', () async {
      final handler = await buildHandler();
      final response = await handler(apiRequest(host: 'evil.example.com'));
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden host');
    });

    test('forbids a cross-origin request to a ServerApi method', () async {
      // api/ping returns early; this covers the ServerApi.handle branch that
      // reaches DeeplinkManager, which spawns a build toolchain process
      // against a caller-supplied path.
      final handler = await buildHandler();
      final response = await handler(
        Request(
          'GET',
          serverUri.resolve('api/androidBuildVariants?rootPath=/tmp'),
          headers: {
            HttpHeaders.hostHeader: 'localhost:9100',
            'Origin': 'https://evil.example.com',
          },
        ),
      );
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden origin');
    });
  });

  group('checks can be disabled', () {
    test('allows a cross-origin request when disabled', () async {
      final handler = await buildHandler(disableOriginCheck: true);
      final response = await handler(
        apiRequest(origin: 'https://evil.example.com'),
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('allows a spoofed Host header when disabled', () async {
      final handler = await buildHandler(disableOriginCheck: true);
      final response = await handler(apiRequest(host: 'evil.example.com'));
      expect(response.statusCode, HttpStatus.ok);
    });
  });
}
