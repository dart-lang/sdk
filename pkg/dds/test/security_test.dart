// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/devtools_server.dart';
import 'package:devtools_shared/devtools_shared.dart';
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

    test(
      'DDS-hosted DevTools allows cross-site iframe navigation to /devtools/ '
      'and forbids /devtools/api/ping',
      () async {
        final dds = await DartDevelopmentService.startDartDevelopmentService(
          remoteVmServiceUri,
          devToolsConfiguration: DevToolsConfiguration(
            enable: true,
            customBuildDirectoryPath: devtoolsAppUri(),
          ),
        );
        final client = HttpClient();
        addTearDown(() async {
          client.close();
          await dds.shutdown();
        });

        final docRequest = await client.getUrl(dds.uri!.resolve('devtools/'));
        docRequest.headers.set('Sec-Fetch-Site', 'cross-site');
        docRequest.headers.set('Sec-Fetch-Dest', 'iframe');
        final docResponse = await docRequest.close();
        expect(docResponse.statusCode, HttpStatus.ok);
        await docResponse.drain();

        final apiRequest = await client.getUrl(
          dds.uri!.resolve('devtools/api/ping'),
        );
        apiRequest.headers.set('Sec-Fetch-Site', 'cross-site');
        apiRequest.headers.set('Sec-Fetch-Dest', 'iframe');
        final apiResponse = await apiRequest.close();
        expect(apiResponse.statusCode, HttpStatus.forbidden);
        await apiResponse.drain();
      },
    );

    group('Legacy package:dds DevToolsServer (in-process)', () {
      group('Host and Origin validation (Enabled by default)', () {
        late HttpServer server;
        late Uri serverUri;
        late HttpClient client;

        setUpAll(() async {
          server = (await DevToolsServer().serveDevTools(
            enableStdinCommands: false,
            dtdInfo: DtdInfo(Uri.parse('ws://127.0.0.1:0')),
          ))!;
          serverUri = Uri.parse(
            'http://${server.address.host}:${server.port}/',
          );
          client = HttpClient();
        });

        tearDownAll(() async {
          client.close();
          await server.close(force: true);
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
              final request = await client.getUrl(
                serverUri.resolve('api/ping'),
              );
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
        late HttpServer server;
        late Uri serverUri;
        late HttpClient client;

        setUpAll(() async {
          server = (await DevToolsServer().serveDevTools(
            enableStdinCommands: false,
            dtdInfo: DtdInfo(Uri.parse('ws://127.0.0.1:0')),
            disableServiceOriginCheck: true,
          ))!;
          serverUri = Uri.parse(
            'http://${server.address.host}:${server.port}/',
          );
          client = HttpClient();
        });

        tearDownAll(() async {
          client.close();
          await server.close(force: true);
        });

        test(
          'allows cross-site Sec-Fetch-Site header without Origin to /api/ping',
          () async {
            final request = await client.getUrl(serverUri.resolve('api/ping'));
            request.headers.set('Sec-Fetch-Site', 'cross-site');
            final response = await request.close();
            expect(response.statusCode, HttpStatus.ok);
            await response.drain();
          },
        );
      });
    });
  });
}
