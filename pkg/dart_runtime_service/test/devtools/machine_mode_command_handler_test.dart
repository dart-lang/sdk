// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sse/server/sse_handler.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

class _FakeSseConnection extends StreamChannelMixin<String>
    implements SseConnection {
  final incoming = StreamController<String>();
  final outgoing = StreamController<String>.broadcast();

  @override
  Stream<String> get stream => incoming.stream;

  @override
  StreamSink<String> get sink => outgoing.sink;

  @override
  bool get isClosed => outgoing.isClosed;

  @override
  bool get isInKeepAlivePeriod => false;

  @override
  void shutdown() {
    incoming.close();
    outgoing.close();
  }
}

class _TestDevToolsServer implements DevToolsServer {
  _TestDevToolsServer({required this.devToolsUrl, required this.headlessMode});

  @override
  DevToolsClientManager? clientManager;

  @override
  final String? devToolsUrl;

  @override
  final bool headlessMode;

  Map<String, Object?>? lastLaunchParams;
  Uri? lastVmServiceUri;
  String? lastDevToolsUrl;
  bool? lastHeadlessMode;
  bool? lastMachineMode;

  @override
  Future<void> launchDevToolsInBrowser({
    required Uri vmServiceUri,
    String? page,
  }) async {}

  @override
  Future<Map<String, Object?>> launchDevTools(
    Map<String, Object?> params,
    Uri vmServiceUri,
    String devToolsUrl,
    bool headlessMode,
    bool machineMode,
  ) async {
    lastLaunchParams = params;
    lastVmServiceUri = vmServiceUri;
    lastDevToolsUrl = devToolsUrl;
    lastHeadlessMode = headlessMode;
    lastMachineMode = machineMode;
    return <String, Object?>{
      'reused': params['reuseWindows'] == true,
      'notified': params['notify'] == true,
      'pid': 12345,
    };
  }
}

class _SpyMachineModeCommandHandler extends MachineModeCommandHandler {
  _SpyMachineModeCommandHandler(super.server, {required super.machineMode});

  Uri? registeredVmServiceUri;
  Object? registeredId;
  String? registeredDevToolsUrl;
  bool? registeredHeadlessMode;

  @override
  Future<void> registerLaunchDevToolsService(
    Uri vmServiceUri,
    Object? id,
    String devToolsUrl,
    bool headlessMode,
  ) async {
    registeredVmServiceUri = vmServiceUri;
    registeredId = id;
    registeredDevToolsUrl = devToolsUrl;
    registeredHeadlessMode = headlessMode;
  }
}

void main() {
  group('MachineModeCommandHandler', () {
    test(
      'vm.register defaults devToolsUrl and headlessMode from server',
      () async {
        final server = _TestDevToolsServer(
          devToolsUrl: 'http://127.0.0.1:9100',
          headlessMode: true,
        );
        final handler = _SpyMachineModeCommandHandler(
          server,
          machineMode: true,
        );

        await handler.handle(
          jsonEncode(<String, Object?>{
            'id': '0',
            'method': 'vm.register',
            'params': <String, Object?>{'uri': 'ws://127.0.0.1:50128/auth=/ws'},
          }),
        );

        expect(
          handler.registeredVmServiceUri,
          Uri.parse('ws://127.0.0.1:50128/auth=/ws'),
        );
        expect(handler.registeredId, '0');
        expect(handler.registeredDevToolsUrl, 'http://127.0.0.1:9100');
        expect(handler.registeredHeadlessMode, isTrue);
      },
    );

    test(
      'vm.register allows explicit devToolsUrl and headless overrides',
      () async {
        final server = _TestDevToolsServer(
          devToolsUrl: 'http://127.0.0.1:9100',
          headlessMode: true,
        );
        final handler = _SpyMachineModeCommandHandler(
          server,
          machineMode: true,
        );

        await handler.handle(
          jsonEncode(<String, Object?>{
            'id': '2',
            'method': 'vm.register',
            'params': <String, Object?>{
              'uri': 'ws://127.0.0.1:50128/auth=/ws',
              'devToolsUrl': 'http://127.0.0.1:9200',
              'headless': false,
            },
          }),
        );

        expect(handler.registeredDevToolsUrl, 'http://127.0.0.1:9200');
        expect(handler.registeredHeadlessMode, isFalse);
      },
    );

    test('ignores non-JSON lines and rejects relative URIs', () async {
      final server = _TestDevToolsServer(
        devToolsUrl: 'http://127.0.0.1:9100',
        headlessMode: true,
      );
      final handler = _SpyMachineModeCommandHandler(server, machineMode: true);

      await handler.handle('not-json');
      await handler.handle(
        jsonEncode(<String, Object?>{
          'id': '3',
          'method': 'vm.register',
          'params': <String, Object?>{'uri': 'relative/path'},
        }),
      );

      expect(handler.registeredVmServiceUri, isNull);
    });

    test('devTools.launch forwards full params, devToolsUrl, and headlessMode '
        'to server.launchDevTools', () async {
      final server = _TestDevToolsServer(
        devToolsUrl: 'http://127.0.0.1:9100',
        headlessMode: true,
      );
      final handler = _SpyMachineModeCommandHandler(server, machineMode: true);

      await handler.handle(
        jsonEncode(<String, Object?>{
          'id': '1',
          'method': 'devTools.launch',
          'params': <String, Object?>{
            'vmServiceUri': 'ws://127.0.0.1:50128/auth=/ws',
            'reuseWindows': true,
            'notify': true,
            'page': 'memory',
          },
        }),
      );

      expect(
        server.lastVmServiceUri,
        Uri.parse('ws://127.0.0.1:50128/auth=/ws'),
      );
      expect(server.lastDevToolsUrl, 'http://127.0.0.1:9100');
      expect(server.lastHeadlessMode, isTrue);
      expect(server.lastMachineMode, isTrue);
      expect(server.lastLaunchParams, isNotNull);
      expect(server.lastLaunchParams!['reuseWindows'], isTrue);
      expect(server.lastLaunchParams!['notify'], isTrue);
      expect(server.lastLaunchParams!['page'], 'memory');
    });
  });

  group('defaultHandler Host and Origin validation', () {
    test('enforces Host and Origin validation by default', () async {
      final server = await HttpServer.bind('127.0.0.1', 0);
      addTearDown(server.close);
      final serverUri = Uri.parse('http://127.0.0.1:${server.port}/');
      final handler = await defaultHandler(
        devtoolsExtensionsManager: ExtensionsManager(),
        serverUri: serverUri,
      );
      shelf_io.serveRequests(server, handler);

      final client = HttpClient();
      addTearDown(client.close);

      // Legitimate request
      final okReq = await client.getUrl(serverUri.resolve('api/ping'));
      final okRes = await okReq.close();
      expect(okRes.statusCode, HttpStatus.ok);
      await okRes.drain<void>();

      // Loopback Origin on another port
      final loopbackOriginReq = await client.getUrl(
        serverUri.resolve('api/ping'),
      );
      loopbackOriginReq.headers.set('Origin', 'http://localhost:1234');
      final loopbackOriginRes = await loopbackOriginReq.close();
      expect(loopbackOriginRes.statusCode, HttpStatus.ok);
      await loopbackOriginRes.drain<void>();

      // Bad Host header
      final badHostReq = await client.getUrl(serverUri.resolve('api/ping'));
      badHostReq.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
      final badHostRes = await badHostReq.close();
      expect(badHostRes.statusCode, HttpStatus.forbidden);
      await badHostRes.drain<void>();

      // Bad Origin header
      final badOriginReq = await client.getUrl(serverUri.resolve('api/ping'));
      badOriginReq.headers.set('Origin', 'http://evil.example.com');
      final badOriginRes = await badOriginReq.close();
      expect(badOriginRes.statusCode, HttpStatus.forbidden);
      await badOriginRes.drain<void>();
    });

    test('disables Host and Origin validation when requested', () async {
      final server = await HttpServer.bind('127.0.0.1', 0);
      addTearDown(server.close);
      final serverUri = Uri.parse('http://127.0.0.1:${server.port}/');
      final handler = await defaultHandler(
        devtoolsExtensionsManager: ExtensionsManager(),
        disableServiceOriginCheck: true,
        serverUri: serverUri,
      );
      shelf_io.serveRequests(server, handler);

      final client = HttpClient();
      addTearDown(client.close);

      final badHostReq = await client.getUrl(serverUri.resolve('api/ping'));
      badHostReq.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
      final badHostRes = await badHostReq.close();
      expect(badHostRes.statusCode, HttpStatus.ok);
      await badHostRes.drain<void>();

      final badOriginReq = await client.getUrl(serverUri.resolve('api/ping'));
      badOriginReq.headers.set('Origin', 'http://evil.example.com');
      final badOriginRes = await badOriginReq.close();
      expect(badOriginRes.statusCode, HttpStatus.ok);
      await badOriginRes.drain<void>();
    });
  });

  group('DevToolsClientManager', () {
    test('does not remove unresponsive clients during SSE keep-alive timeout '
        'and only reuses unconnected clients in findReusableClient', () async {
      final manager = DevToolsClientManager(
        requestNotificationPermissions: false,
      );
      final sse = _FakeSseConnection();
      addTearDown(() async {
        await sse.incoming.close();
        await sse.outgoing.close();
      });

      manager.acceptClient(sse);
      final vmServiceUri = Uri.parse('ws://127.0.0.1:50128/auth=/ws');
      sse.incoming.add(
        jsonEncode(<String, Object?>{
          'jsonrpc': '2.0',
          'method': 'currentPage',
          'params': <String, Object?>{'id': 'logging', 'embedded': false},
        }),
      );
      sse.incoming.add(
        jsonEncode(<String, Object?>{
          'jsonrpc': '2.0',
          'method': 'connected',
          'params': <String, Object?>{'uri': vmServiceUri.toString()},
        }),
      );
      await pumpEventQueue();

      // Connected client should not be returned by findReusableClient().
      expect(await manager.findReusableClient(), isNull);

      // Client does not respond to ping, so findExistingConnectedReusableClient
      // returns null, but the client remains in _clients until SSE sink closes.
      expect(
        await manager.findExistingConnectedReusableClient(vmServiceUri),
        isNull,
      );
      final json = manager.toJson('1');
      final result = json['result'] as Map<String, Object?>;
      final clients = result['clients'] as List<Object?>;
      expect(clients, hasLength(1));

      // Once SSE connection closes, client is removed.
      await sse.outgoing.close();
      await pumpEventQueue();
      final jsonAfterClose = manager.toJson('2');
      final resultAfterClose = jsonAfterClose['result'] as Map<String, Object?>;
      expect(resultAfterClose['clients'] as List<Object?>, isEmpty);
    });
  });
}
