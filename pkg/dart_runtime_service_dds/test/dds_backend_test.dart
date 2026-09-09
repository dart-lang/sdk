// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_dds/dart_runtime_service_dds.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:web_socket_channel/io.dart';

class MockVmService {
  MockVmService._(this.server, this.port);

  final HttpServer server;
  final int port;
  final clients = <json_rpc.Peer>[];

  Uri get uri => Uri.parse('http://localhost:$port/');

  static Future<MockVmService> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = MockVmService._(server, server.port);

    server.transform(WebSocketTransformer()).listen((webSocket) {
      final channel = IOWebSocketChannel(webSocket);
      final peer = json_rpc.Peer(channel.cast<String>());
      mock.clients.add(peer);

      peer.registerMethod('getVM', (json_rpc.Parameters params) {
        return {
          'type': 'VM',
          'name': 'mock-vm',
          'isolates': <Map<String, Object?>>[],
        };
      });

      peer.registerMethod('streamListen', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('getVersion', (json_rpc.Parameters params) {
        return vm.Version(major: 4, minor: 0).toJson();
      });

      peer.registerMethod('getSupportedProtocols', (
        json_rpc.Parameters params,
      ) {
        return vm.ProtocolList(
          protocols: [
            vm.Protocol(protocolName: 'VM Service', major: 4, minor: 0),
          ],
        ).toJson();
      });

      peer.registerMethod('getFlagList', (json_rpc.Parameters params) {
        return vm.FlagList(
          flags: [
            vm.Flag(name: 'pause_isolates_on_start', valueAsString: 'false'),
            vm.Flag(name: 'pause_isolates_on_exit', valueAsString: 'false'),
          ],
        ).toJson();
      });

      peer.listen();
    });

    return mock;
  }

  Future<void> shutdown() async {
    for (final client in clients) {
      await client.close();
    }
    await server.close();
  }
}

void main() {
  group('DartRuntimeServiceDdsBackend', () {
    MockVmService? mockVmService;
    DartRuntimeService? ddsService;
    vm.VmService? ddsClient;

    setUp(() async {
      mockVmService = await MockVmService.start();

      ddsService = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => DartRuntimeServiceDdsBackend(
          mockVmService!.uri,
          frontend: frontend,
        ),
      );

      ddsClient = await vmServiceConnectUri(ddsService!.uri.toString());
    });

    tearDown(() async {
      await ddsClient?.dispose();
      await ddsService?.shutdown();
      await mockVmService?.shutdown();
    });

    test('forward RPC request', () async {
      final vmResult = await ddsClient!.getVM();
      expect(vmResult.name, 'mock-vm');
    });

    test('getVersion returns VM Service version', () async {
      final version = await ddsClient!.getVersion();
      expect(version.major, 4);
      expect(version.minor, 0);
    });

    test('getDartDevelopmentServiceVersion returns DDS version', () async {
      final version = await ddsClient!.getDartDevelopmentServiceVersion();
      expect(version.type, 'Version');
      expect(version.major, 2);
      expect(version.minor, 1);
    });

    test(
      'getSupportedProtocols returns protocols list including DDS',
      () async {
        final protocols = await ddsClient!.getSupportedProtocols();
        final ddsProto = protocols.protocols!.firstWhere(
          (p) => p.protocolName == 'DDS',
        );
        expect(ddsProto.major, 2);
        expect(ddsProto.minor, 1);
      },
    );

    test('does not start DTD when serveDevTools is false', () async {
      late DartRuntimeServiceDdsBackend backend;
      final service = await DartRuntimeService.initialize(
        // Note: serveDevTools defaults to false. It is omitted here to adhere
        // to the avoid_redundant_argument_values lint.
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => backend = DartRuntimeServiceDdsBackend(
          mockVmService!.uri,
          frontend: frontend,
        ),
      );
      expect(backend.hostedDartToolingDaemon, isNull);
      await service.shutdown();
    });

    test('starts DTD when serveDevTools is true', () async {
      late DartRuntimeServiceDdsBackend backend;
      final service = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(serveDevTools: true),
        backendBuilder: (frontend) => backend = DartRuntimeServiceDdsBackend(
          mockVmService!.uri,
          frontend: frontend,
          serveDevTools: true,
        ),
      );
      expect(backend.hostedDartToolingDaemon, isNotNull);
      await service.shutdown();
    });
  });

  group('DevTools hosting', () {
    late MockVmService mockVmService;
    late Directory tempDir;

    setUp(() async {
      mockVmService = await MockVmService.start();
      tempDir = Directory.systemTemp.createTempSync('devtools_test');
      File(
        path.join(tempDir.path, 'index.html'),
      ).writeAsStringSync('<html><body>DevTools</body></html>');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      await mockVmService.shutdown();
    });

    test('serve DevTools assets', () async {
      late DartRuntimeServiceDdsBackend backend;
      final service = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(serveDevTools: true),
        backendBuilder: (frontend) => backend = DartRuntimeServiceDdsBackend(
          mockVmService.uri,
          frontend: frontend,
          customDevToolsPath: tempDir.uri,
          serveDevTools: true,
        ),
      );

      final devToolsUri = backend.devToolsUri;
      expect(devToolsUri, isNotNull);

      final client = HttpClient();
      final request = await client.getUrl(devToolsUri!);
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);

      final body = await response.transform(utf8.decoder).join();
      expect(body, '<html><body>DevTools</body></html>');

      client.close();
      await service.shutdown();
    });

    test('redirect to external DevTools', () async {
      late DartRuntimeServiceDdsBackend backend;
      final service = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => backend = DartRuntimeServiceDdsBackend(
          mockVmService.uri,
          frontend: frontend,
        ),
      );

      final client = HttpClient();

      final ddsHttpUri = service.httpUri;
      final devtoolsReqUri = ddsHttpUri.replace(
        pathSegments: [
          ...ddsHttpUri.pathSegments.where((e) => e.isNotEmpty),
          'devtools',
        ],
      );

      final request1 = await client.getUrl(devtoolsReqUri);
      request1.followRedirects = false;
      final response1 = await request1.close();
      expect(response1.statusCode, HttpStatus.notFound);
      await response1.drain<void>();

      final externalUri = Uri.parse('http://localhost:1234/custom');
      backend.setExternalDevToolsUri(externalUri);

      expect(backend.devToolsUri, isNotNull);
      expect(
        backend.devToolsUri.toString(),
        startsWith('http://localhost:1234/custom?uri='),
      );

      final request2 = await client.getUrl(devtoolsReqUri);
      request2.followRedirects = false;
      final response2 = await request2.close();
      expect(response2.statusCode, HttpStatus.seeOther);
      expect(
        response2.headers.value(HttpHeaders.locationHeader),
        startsWith(externalUri.toString()),
      );
      await response2.drain<void>();

      client.close();
      await service.shutdown();
    });
  });
}
