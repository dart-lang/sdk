// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/data/build_result.dart';
import 'package:dwds/data/connect_request.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/handlers/dev_handler.dart';
import 'package:dwds/src/handlers/injector.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:dwds_test_common/fixtures/fakes.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const _bootstrapPath = '/main.dart.bootstrap.js';
const _devHandlerPath = r'/$dwdsSseHandler';
const _sseClientId = 'test-client-id';
const _xForwardedHostHeader = 'X-Forwarded-Host';

class _TestHarness {
  final HttpServer server;
  final DevHandler devHandler;
  final HttpClient client;

  _TestHarness._(this.server, this.devHandler, this.client);

  int get port => server.port;

  Uri wsUri([String path = _devHandlerPath]) =>
      Uri.parse('ws://127.0.0.1:$port$path');

  Uri httpUri(String path, [Map<String, String>? query]) =>
      Uri.http('127.0.0.1:$port', path, query);

  Future<int> sendHttp({
    required String path,
    String? host,
    String? origin,
    Map<String, String> extraHeaders = const <String, String>{},
    Map<String, String>? query,
  }) async {
    final request = await client.getUrl(httpUri(path, query));
    if (host != null) request.headers.set(HttpHeaders.hostHeader, host);
    if (origin != null) request.headers.set('origin', origin);
    for (final MapEntry(:key, :value) in extraHeaders.entries) {
      request.headers.set(key, value);
    }
    final response = await request.close();
    if (response.statusCode == HttpStatus.ok &&
        response.headers.contentType?.mimeType == 'text/event-stream') {
      // Cancel the long-lived SSE stream without waiting for EOF.
      final sub = response.listen((_) {});
      await sub.cancel();
    } else {
      await response.drain<void>();
    }
    return response.statusCode;
  }

  Future<WebSocket> connectWebSocket({String? host, String? origin}) =>
      WebSocket.connect(
        wsUri().toString(),
        headers: <String, Object>{
          HttpHeaders.hostHeader: ?host,
          'Origin': ?origin,
        },
      );

  Future<void> close() async {
    client.close(force: true);
    await devHandler.close();
    await server.close(force: true);
  }
}

Future<_TestHarness> _startHarness({
  String hostname = 'localhost',
  bool useSse = false,
  UrlEncoder? urlEncoder,
}) async {
  final assetReader = FakeAssetReader();
  final debugSettings = DebugSettings(
    enableDebugging: false,
    useSseForInjectedClient: useSse,
    urlEncoder: urlEncoder,
    ddsConfiguration: const DartDevelopmentServiceConfiguration(enable: false),
  );
  globalToolConfiguration = ToolConfiguration(
    loadStrategy: FakeStrategy(assetReader),
    debugSettings: debugSettings,
    appMetadata: AppMetadata(hostname: hostname),
  );
  final injector = DwdsInjector();
  final devHandler = DevHandler(
    () => Future<ChromeConnection>.error(UnimplementedError()),
    const Stream<BuildResult>.empty(),
    null,
    assetReader,
    hostname,
    null,
    urlEncoder,
    true,
    useSse,
    null,
    injector,
    debugSettings.ddsConfiguration,
    false,
  );
  final pipeline = const Pipeline().addMiddleware(injector.middleware);
  final cascade = Cascade()
      .add(devHandler.handler)
      .add(
        pipeline.addHandler(
          (request) => request.url.path == 'main.dart.bootstrap.js'
              ? Response.ok(
                  '$entrypointExtensionMarker\n$mainExtensionMarker\nmain();',
                )
              : Response.notFound(''),
        ),
      );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  serveHttpRequests(server, cascade.handler, (_, _) {});
  final client = HttpClient();
  final harness = _TestHarness._(server, devHandler, client);
  // Trigger DwdsInjector to register the DevHandler path deterministically.
  final status = await harness.sendHttp(path: _bootstrapPath);
  expect(status, HttpStatus.ok);
  return harness;
}

void main() {
  group('DevHandler Host and Origin validation', () {
    test('rejects invalid, cross-origin, and DNS-rebound requests', () async {
      final harness = await _startHarness();
      addTearDown(harness.close);
      final p = harness.port;

      final rejectedCases = <({String name, String? host, String? origin})>[
        (name: 'cross-origin', host: null, origin: 'http://evil.test:$p'),
        (name: 'null origin', host: null, origin: 'null'),
        (
          name: 'path-bearing origin',
          host: null,
          origin: 'http://localhost:$p/foo',
        ),
        (
          name: 'percent-escaped origin',
          host: null,
          origin: 'http://%6cocalhost:$p',
        ),
        (
          name: 'comma-joined origins',
          host: null,
          origin: 'http://localhost:$p, http://evil.test',
        ),
        (
          name: 'DNS-rebound host on localhost bind',
          host: 'evil.test:$p',
          origin: 'http://evil.test:$p',
        ),
        (
          name: 'cross-port non-loopback IP',
          host: '192.168.1.10:$p',
          origin: 'http://192.168.1.10:9999',
        ),
      ];

      for (final (:name, :host, :origin) in rejectedCases) {
        expect(
          await harness.sendHttp(
            path: _devHandlerPath,
            host: host,
            origin: origin,
          ),
          HttpStatus.forbidden,
          reason: name,
        );
      }

      // Unmatched paths must continue returning 404 for shelf.Cascade.
      expect(await harness.sendHttp(path: '/index.html'), HttpStatus.notFound);
    });

    test('rejects X-Forwarded-Host bypass of Host validation', () async {
      final harness = await _startHarness();
      addTearDown(harness.close);
      final p = harness.port;

      expect(
        await harness.sendHttp(
          path: _devHandlerPath,
          host: 'evil.test:$p',
          origin: 'http://localhost:$p',
          extraHeaders: <String, String>{_xForwardedHostHeader: 'localhost:$p'},
        ),
        HttpStatus.forbidden,
      );
    });

    test('rejects X-Forwarded-Host spoofing of Origin validation', () async {
      final harness = await _startHarness(hostname: '0.0.0.0');
      addTearDown(harness.close);
      final p = harness.port;

      expect(
        await harness.sendHttp(
          path: _devHandlerPath,
          host: 'localhost:$p',
          origin: 'http://evil.test:$p',
          extraHeaders: <String, String>{_xForwardedHostHeader: 'evil.test:$p'},
        ),
        HttpStatus.forbidden,
      );
    });

    test('rejects requests without a Host header', () async {
      final harness = await _startHarness();
      addTearDown(harness.close);

      final response = await harness.devHandler.handler(
        Request('GET', harness.httpUri(_devHandlerPath)),
      );
      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('accepts same-origin, loopback alias, and same-origin IP', () async {
      final harness = await _startHarness();
      addTearDown(harness.close);
      final p = harness.port;

      final acceptedCases = <({String name, String host, String origin})>[
        (
          name: 'same-origin localhost',
          host: 'localhost:$p',
          origin: 'http://localhost:$p',
        ),
        (
          name: 'cross-port loopback alias',
          host: 'localhost:$p',
          origin: 'http://127.0.0.1:3000',
        ),
        (
          name: 'same-origin non-loopback IP',
          host: '192.168.1.10:$p',
          origin: 'http://192.168.1.10:$p',
        ),
      ];

      for (final (:name, :host, :origin) in acceptedCases) {
        final ws = await harness.connectWebSocket(host: host, origin: origin);
        expect(ws.readyState, WebSocket.open, reason: name);
        await ws.close();
      }
    });

    test(
      'wildcard bind allows matching custom DNS Host and rejects mismatch',
      () async {
        final harness = await _startHarness(hostname: '0.0.0.0');
        addTearDown(harness.close);
        final p = harness.port;

        final ws = await harness.connectWebSocket(
          host: 'devbox.example.com:$p',
          origin: 'http://devbox.example.com:$p',
        );
        await ws.close();

        expect(
          await harness.sendHttp(
            path: _devHandlerPath,
            host: 'devbox.example.com:$p',
            origin: 'http://evil.example.com:$p',
          ),
          HttpStatus.forbidden,
        );
      },
    );

    test(
      'configured custom hostname allows matching Host and rejects other Host',
      () async {
        final harness = await _startHarness(hostname: 'devbox.example.com');
        addTearDown(harness.close);
        final p = harness.port;

        final ws = await harness.connectWebSocket(
          host: 'devbox.example.com:$p',
          origin: 'http://devbox.example.com:$p',
        );
        await ws.close();

        expect(
          await harness.sendHttp(
            path: _devHandlerPath,
            host: 'other.example.com:$p',
            origin: 'http://other.example.com:$p',
          ),
          HttpStatus.forbidden,
        );
      },
    );

    test(
      'TLS-terminating proxy with urlEncoder works in WebSocket and SSE modes',
      () async {
        const proxyHost = 'pen.proxy.example.com';
        const proxyOrigin = 'https://pen.proxy.example.com';
        const evilOrigin = 'https://evil.example.com';

        final wsHarness = await _startHarness(urlEncoder: (url) async => url);
        addTearDown(wsHarness.close);
        final ws = await wsHarness.connectWebSocket(
          host: proxyHost,
          origin: proxyOrigin,
        );
        await ws.close();
        expect(
          await wsHarness.sendHttp(
            path: _devHandlerPath,
            host: proxyHost,
            origin: evilOrigin,
          ),
          HttpStatus.forbidden,
        );

        final sseHarness = await _startHarness(
          useSse: true,
          urlEncoder: (url) async => url,
        );
        addTearDown(sseHarness.close);
        expect(
          await sseHarness.sendHttp(
            path: _devHandlerPath,
            host: proxyHost,
            origin: proxyOrigin,
            extraHeaders: const <String, String>{
              HttpHeaders.acceptHeader: 'text/event-stream',
            },
            query: const <String, String>{'sseClientId': _sseClientId},
          ),
          HttpStatus.ok,
        );
        expect(
          await sseHarness.sendHttp(
            path: _devHandlerPath,
            host: proxyHost,
            origin: evilOrigin,
            extraHeaders: const <String, String>{
              HttpHeaders.acceptHeader: 'text/event-stream',
            },
            query: const <String, String>{'sseClientId': _sseClientId},
          ),
          HttpStatus.forbidden,
        );
      },
    );

    test('SSE rejects no-cors cross-site requests without Origin', () async {
      final harness = await _startHarness(useSse: true);
      addTearDown(harness.close);
      expect(
        await harness.sendHttp(
          path: _devHandlerPath,
          extraHeaders: const <String, String>{
            HttpHeaders.acceptHeader: 'text/event-stream',
            'Sec-Fetch-Site': 'cross-site',
          },
          query: const <String, String>{'sseClientId': _sseClientId},
        ),
        HttpStatus.forbidden,
      );
    });

    test('connectedApps emits only for valid WS and SSE connections', () async {
      final payload = jsonEncode(<Object>[
        'ConnectRequest',
        ConnectRequest(
          appId: 'app-1',
          instanceId: 'inst-1',
          entrypointPath: 'main.dart',
        ).toJson(),
      ]);

      // WebSocket mode
      final wsHarness = await _startHarness();
      addTearDown(wsHarness.close);
      final wsApps = <String>[];
      final wsSub = wsHarness.devHandler.connectedApps.listen(
        (c) => wsApps.add(c.request.appId),
      );
      addTearDown(wsSub.cancel);

      await expectLater(
        wsHarness.connectWebSocket(
          origin: 'http://evil.test:${wsHarness.port}',
        ),
        throwsA(isA<WebSocketException>()),
      );
      expect(wsApps, isEmpty);

      final wsConnected = wsHarness.devHandler.connectedApps.first;
      final ws = await wsHarness.connectWebSocket(
        host: 'localhost:${wsHarness.port}',
        origin: 'http://localhost:${wsHarness.port}',
      );
      ws.add(payload);
      expect((await wsConnected).request.appId, 'app-1');
      await ws.close();

      // SSE mode
      final sseHarness = await _startHarness(useSse: true);
      addTearDown(sseHarness.close);
      final sseApps = <String>[];
      final sseSub = sseHarness.devHandler.connectedApps.listen(
        (c) => sseApps.add(c.request.appId),
      );
      addTearDown(sseSub.cancel);

      expect(
        await sseHarness.sendHttp(
          path: _devHandlerPath,
          origin: 'http://evil.test:${sseHarness.port}',
          extraHeaders: const <String, String>{
            HttpHeaders.acceptHeader: 'text/event-stream',
          },
          query: const <String, String>{'sseClientId': _sseClientId},
        ),
        HttpStatus.forbidden,
      );
      expect(sseApps, isEmpty);

      final sseConnected = sseHarness.devHandler.connectedApps.first;
      final sseReq = await sseHarness.client.getUrl(
        sseHarness.httpUri(_devHandlerPath, const <String, String>{
          'sseClientId': _sseClientId,
        }),
      );
      sseReq.headers
        ..set(HttpHeaders.hostHeader, 'localhost:${sseHarness.port}')
        ..set('origin', 'http://localhost:${sseHarness.port}')
        ..set(HttpHeaders.acceptHeader, 'text/event-stream');
      final sseResp = await sseReq.close();
      expect(sseResp.statusCode, HttpStatus.ok);
      final sseStreamSub = sseResp.listen((_) {});
      addTearDown(sseStreamSub.cancel);

      final postReq = await sseHarness.client.postUrl(
        sseHarness.httpUri(_devHandlerPath, const <String, String>{
          'sseClientId': _sseClientId,
          'messageId': '0',
        }),
      );
      postReq.headers
        ..set(HttpHeaders.hostHeader, 'localhost:${sseHarness.port}')
        ..set('origin', 'http://localhost:${sseHarness.port}');
      postReq.write(jsonEncode(payload));
      final postResp = await postReq.close();
      await postResp.drain<void>();
      expect(postResp.statusCode, HttpStatus.ok);
      expect((await sseConnected).request.appId, 'app-1');
    });
  });
}
