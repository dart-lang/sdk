// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service_io.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
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

  group('Host and Origin security when bound by hostname:', () {
    late HttpClient client;
    DartRuntimeService? service;
    InternetAddress? bindAddress;

    setUp(() async {
      client = HttpClient();
      final hostname = Platform.localHostname;
      bindAddress = await resolveBindAddress(hostname);
      if (bindAddress == null || bindAddress!.isLoopback) return;
      service = await createDartRuntimeServiceForTest(
        config: DartRuntimeServiceOptions(
          enableLogging: true,
          disableAuthCodes: true,
          host: hostname,
        ),
      );
    });

    tearDown(() {
      client.close();
      service = null;
    });

    /// Sends a request to the bound address with the given [hostHeader] and
    /// [origin], and returns the response status code.
    Future<int> statusFor({String? hostHeader, String? origin}) async {
      final uri = service!.httpUri.replace(host: bindAddress!.address);
      final request = await client.getUrl(uri);
      if (hostHeader != null) {
        request.headers.set(HttpHeaders.hostHeader, hostHeader);
      }
      if (origin != null) request.headers.set('Origin', origin);
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    }

    /// Returns `true` and marks the test skipped if this machine's hostname
    /// doesn't resolve to a non-loopback address.
    bool skipIfNoHostname() {
      if (service != null) return false;
      markTestSkipped(
        '${Platform.localHostname} does not resolve to a non-loopback address.',
      );
      return true;
    }

    test('allows Host header with the configured hostname', () async {
      if (skipIfNoHostname()) return;
      final port = service!.uri.port;
      expect(
        await statusFor(hostHeader: '${service!.uri.host}:$port'),
        isNot(equals(HttpStatus.forbidden)),
      );
    });

    test('allows Host header with the bound IP address', () async {
      if (skipIfNoHostname()) return;
      final port = service!.uri.port;
      expect(
        await statusFor(hostHeader: '${bindAddress!.address}:$port'),
        isNot(equals(HttpStatus.forbidden)),
      );
    });

    test('allows Origin header with the bound IP address', () async {
      if (skipIfNoHostname()) return;
      final origin = service!.httpUri.replace(host: bindAddress!.address);
      expect(
        await statusFor(origin: origin.origin),
        isNot(equals(HttpStatus.forbidden)),
      );
    });

    test(
      'forbids Host header with the bound IP address on another port',
      () async {
        if (skipIfNoHostname()) return;
        final otherPort = service!.uri.port + 1;
        expect(
          await statusFor(hostHeader: '${bindAddress!.address}:$otherPort'),
          equals(HttpStatus.forbidden),
        );
      },
    );
  });

  group('DevTools handler security:', () {
    group(
      'Host, Origin, and Sec-Fetch-Site validation (Enabled by default)',
      () {
        late HttpServer server;
        late Uri serverUri;
        late HttpClient client;

        setUpAll(() async {
          server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          serverUri = Uri(
            scheme: 'http',
            host: server.address.host,
            port: server.port,
          );
          final handler = await defaultHandler(
            devtoolsExtensionsManager: ExtensionsManager(),
            serverUri: serverUri,
          );
          shelf_io.serveRequests(server, handler);
          client = HttpClient();
        });

        tearDownAll(() async {
          client.close();
          await server.close(force: true);
        });

        test('allows legitimate GET request to /api/ping', () async {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          final response = await request.close();
          expect(response.statusCode, HttpStatus.ok);
          await response.drain<void>();
        });

        test('forbids GET request with bad Host header to /api/ping', () async {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.forbidden);
          await response.drain<void>();
        });

        test(
          'forbids GET request with bad Origin header to /api/ping',
          () async {
            final request = await client.getUrl(serverUri.resolve('api/ping'));
            request.headers.set('Origin', 'http://evil.example.com');
            final response = await request.close();
            expect(response.statusCode, HttpStatus.forbidden);
            await response.drain<void>();
          },
        );

        for (final (site, status) in [
          ('cross-site', HttpStatus.forbidden),
          ('same-site', HttpStatus.forbidden),
          ('same-origin', HttpStatus.ok),
          ('none', HttpStatus.ok),
        ]) {
          test('returns $status for GET request without Origin and with '
              'Sec-Fetch-Site: $site to /api/ping', () async {
            final request = await client.getUrl(serverUri.resolve('api/ping'));
            request.headers.set('Sec-Fetch-Site', site);
            final response = await request.close();
            expect(response.statusCode, status);
            await response.drain<void>();
          });
        }

        test('forbids GET request without Origin and with cross-site '
            'Sec-Fetch-Site header to /api/sse', () async {
          final request = await client.getUrl(serverUri.resolve('api/sse'));
          request.headers.set('Sec-Fetch-Site', 'cross-site');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.forbidden);
          await response.drain<void>();
        });

        test('allows GET request with loopback Origin and same-site '
            'Sec-Fetch-Site header to /api/ping', () async {
          final request = await client.getUrl(serverUri.resolve('api/ping'));
          request.headers.set('Origin', 'http://localhost:12345');
          request.headers.set('Sec-Fetch-Site', 'same-site');
          final response = await request.close();
          expect(response.statusCode, HttpStatus.ok);
          await response.drain<void>();
        });
      },
    );

    group('Disable Origin Check', () {
      late HttpServer server;
      late Uri serverUri;
      late HttpClient client;

      setUpAll(() async {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        serverUri = Uri(
          scheme: 'http',
          host: server.address.host,
          port: server.port,
        );
        final handler = await defaultHandler(
          devtoolsExtensionsManager: ExtensionsManager(),
          serverUri: serverUri,
          disableServiceOriginCheck: true,
        );
        shelf_io.serveRequests(server, handler);
        client = HttpClient();
      });

      tearDownAll(() async {
        client.close();
        await server.close(force: true);
      });

      test('allows bad Host, Origin, and cross-site Sec-Fetch-Site to '
          '/api/ping', () async {
        final request = await client.getUrl(serverUri.resolve('api/ping'));
        request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
        request.headers.set('Sec-Fetch-Site', 'cross-site');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.ok);
        await response.drain<void>();
      });
    });
  });
}
