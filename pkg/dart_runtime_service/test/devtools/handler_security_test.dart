// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Additional coverage for the Host and Origin checks applied to `api/*` in
// `defaultHandler`. The `defaultHandler Host and Origin validation` group in
// machine_mode_command_handler_test.dart drives the handler through a real
// `HttpServer`, which covers the common cases but cannot reach a few branches:
// `HttpClient` always sends a Host header, and a loopback `serverUri` means the
// `allowedUris` comparison is short-circuited by the loopback check before it
// is ever evaluated. These tests invoke the handler directly instead.

import 'dart:async';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service_io.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final loopbackServerUri = Uri.parse('http://127.0.0.1:9100/');

/// A server address that is not loopback, so that allowing an origin requires
/// an actual match against `allowedUris`.
final remoteServerUri = Uri.parse('http://devbox.internal:9100/');

FutureOr<Handler> buildHandler({
  required Uri serverUri,
  Uri? Function()? serviceUriGetter,
}) {
  return defaultHandler(
    devtoolsExtensionsManager: ExtensionsManager(),
    serverUri: serverUri,
    serviceUriGetter: serviceUriGetter,
  );
}

/// Builds a request for an `api/*` endpoint with a Host header matching
/// [serverUri], omitting the Origin header entirely when [origin] is `null`.
Request apiRequest(
  Uri serverUri, {
  String path = 'api/ping',
  String? origin,
}) {
  final headers = <String, String>{
    HttpHeaders.hostHeader: '${serverUri.host}:${serverUri.port}',
  };
  if (origin != null) {
    headers['Origin'] = origin;
  }
  return Request('GET', serverUri.resolve(path), headers: headers);
}

void main() {
  group('defaultHandler api/* Host and Origin checks:', () {
    test('forbids a request with no Host header', () async {
      final handler = await buildHandler(serverUri: loopbackServerUri);
      final response = await handler(
        Request('GET', loopbackServerUri.resolve('api/ping')),
      );
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden host');
    });

    test('forbids a malformed Origin header', () async {
      final handler = await buildHandler(serverUri: loopbackServerUri);
      final response = await handler(
        apiRequest(loopbackServerUri, origin: 'http://[[['),
      );
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden origin');
    });

    test('allows an Origin matching a non-loopback server URI', () async {
      final handler = await buildHandler(serverUri: remoteServerUri);
      final response = await handler(
        apiRequest(remoteServerUri, origin: 'http://devbox.internal:9100'),
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('forbids an Origin on another host at the same port', () async {
      final handler = await buildHandler(serverUri: remoteServerUri);
      final response = await handler(
        apiRequest(remoteServerUri, origin: 'http://evil.example.com:9100'),
      );
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden origin');
    });

    test('allows an Origin matching the URI from serviceUriGetter', () async {
      final serviceUri = Uri.parse('http://devbox.internal:9200/');
      final handler = await buildHandler(
        serverUri: remoteServerUri,
        serviceUriGetter: () => serviceUri,
      );
      final response = await handler(
        apiRequest(remoteServerUri, origin: 'http://devbox.internal:9200'),
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('forbids a cross-origin request to an api method other than '
        'ping', () async {
      // api/ping returns before reaching ServerApi, so this covers the branch
      // that dispatches to DeeplinkManager, which spawns a build toolchain
      // process against a caller-supplied path.
      final handler = await buildHandler(serverUri: loopbackServerUri);
      final response = await handler(
        apiRequest(
          loopbackServerUri,
          path: 'api/androidBuildVariants?rootPath=/tmp',
          origin: 'https://evil.example.com',
        ),
      );
      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.readAsString(), 'forbidden origin');
    });
  });
}
