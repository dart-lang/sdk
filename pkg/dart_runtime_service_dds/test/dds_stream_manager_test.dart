// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_dds/dart_runtime_service_dds.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:web_socket_channel/io.dart';

class MockVmService {
  MockVmService._(this.server, this.port);

  final HttpServer server;
  final int port;
  final clients = <json_rpc.Peer>[];
  final listenedStreams = <String>{};
  final cancelledStreams = <String>{};

  Uri get uri => Uri.parse('http://localhost:$port/');

  static Future<MockVmService> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = MockVmService._(server, server.port);

    server.transform(WebSocketTransformer()).listen((webSocket) {
      final channel = IOWebSocketChannel(webSocket);
      final peer = json_rpc.Peer(channel.cast<String>());
      mock.clients.add(peer);

      peer.registerMethod('getVM', (json_rpc.Parameters params) {
        return <String, Object?>{
          'type': 'VM',
          'name': 'mock-vm',
          'isolates': <Map<String, Object?>>[],
        };
      });

      peer.registerMethod('_yieldControlToDDS', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('getVersion', (json_rpc.Parameters params) {
        return vm.Version(major: 4, minor: 0).toJson();
      });

      peer.registerMethod('streamListen', (json_rpc.Parameters params) {
        final streamId = params['streamId'].asString;
        mock.listenedStreams.add(streamId);
        return vm.Success().toJson();
      });

      peer.registerMethod('streamCancel', (json_rpc.Parameters params) {
        final streamId = params['streamId'].asString;
        mock.cancelledStreams.add(streamId);
        return vm.Success().toJson();
      });

      peer.registerMethod('getFlagList', (json_rpc.Parameters params) {
        return vm.FlagList(
          flags: <vm.Flag>[
            vm.Flag(name: 'pause_isolates_on_start', valueAsString: 'false'),
            vm.Flag(name: 'pause_isolates_on_exit', valueAsString: 'false'),
          ],
        ).toJson();
      });

      peer.listen();
    });

    return mock;
  }

  void emitEvent(String streamId, vm.Event event) {
    for (final client in clients) {
      client.sendNotification('streamNotify', <String, Object?>{
        'streamId': streamId,
        'event': event.toJson(),
      });
    }
  }

  Future<void> shutdown() async {
    for (final client in clients) {
      await client.close();
    }
    await server.close(force: true);
  }
}

void main() {
  group('DdsStreamManager', () {
    late MockVmService mockVmService;
    late DartRuntimeService ddsService;
    late DartRuntimeServiceDdsBackend backend;
    late vm.VmService ddsClient;

    setUp(() async {
      mockVmService = await MockVmService.start();

      ddsService = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => backend = DartRuntimeServiceDdsBackend(
          mockVmService.uri,
          frontend: frontend,
        ),
      );

      ddsClient = await vmServiceConnectUri(ddsService.uri.toString());
    });

    tearDown(() async {
      await ddsClient.dispose();
      await ddsService.shutdown();
      await mockVmService.shutdown();
    });

    test('initializes core streams and records stream history', () async {
      final streamManager = backend.streamManager;
      expect(
        mockVmService.listenedStreams,
        containsAll(<String>[
          vm.EventStreams.kDebug,
          vm.EventStreams.kIsolate,
          vm.EventStreams.kLogging,
          vm.EventStreams.kStdout,
          vm.EventStreams.kStderr,
          vm.EventStreams.kExtension,
          vm.EventStreams.kTimeline,
        ]),
      );

      final eventCompleter = Completer<vm.Event>();
      ddsClient.onLoggingEvent.listen(eventCompleter.complete);
      await ddsClient.streamListen(vm.EventStreams.kLogging);

      final testEvent = vm.Event(
        kind: vm.EventKind.kLogging,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        logRecord: vm.LogRecord(
          message: vm.InstanceRef(
            id: 'objects/test-msg',
            kind: vm.InstanceKind.kString,
            valueAsString: 'hello logging',
          ),
          time: 0,
          level: 0,
          sequenceNumber: 1,
          loggerName: vm.InstanceRef(
            id: 'objects/test-logger',
            kind: vm.InstanceKind.kString,
            valueAsString: 'test',
          ),
        ),
      );

      mockVmService.emitEvent(vm.EventStreams.kLogging, testEvent);

      final receivedEvent = await eventCompleter.future;
      expect(receivedEvent.kind, vm.EventKind.kLogging);

      final history = streamManager.getStreamHistory(vm.EventStreams.kLogging);
      expect(history, isNotNull);
      expect(history, isNotEmpty);
    });

    test('getLogHistorySize and setLogHistorySize resize buffer', () {
      final streamManager = backend.streamManager;
      expect(streamManager.getLogHistorySize(), greaterThan(0));

      streamManager.setLogHistorySize(50);
      expect(streamManager.getLogHistorySize(), 50);

      expect(
        () => streamManager.setLogHistorySize(-1),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });

    test(
      'postEvent rejects core streams and broadcasts custom events',
      () async {
        final streamManager = backend.streamManager;

        expect(
          () => streamManager.postEvent(
            vm.EventStreams.kLogging,
            'CustomKind',
            <String, Object?>{},
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (e) => e.code,
              'code',
              vm.RPCErrorKind.kCoreStreamNotAllowed.code,
            ),
          ),
        );

        const customStream = 'CustomStream';
        final eventCompleter = Completer<vm.Event>();
        ddsClient.onEvent(customStream).listen(eventCompleter.complete);
        await ddsClient.streamListen(customStream);

        streamManager.postEvent(customStream, 'CustomKind', <String, Object?>{
          'key': 'value',
        });

        final received = await eventCompleter.future;
        expect(received.extensionKind, 'CustomKind');
        expect(received.extensionData?.data['key'], 'value');
      },
    );

    test('handles extension event destination redirection', () async {
      const destinationStream = 'RedirectedStream';
      final eventCompleter = Completer<vm.Event>();
      ddsClient.onEvent(destinationStream).listen(eventCompleter.complete);
      await ddsClient.streamListen(destinationStream);

      final extensionEvent = vm.Event(
        kind: vm.EventKind.kExtension,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        extensionKind: 'CustomExt',
        extensionData: vm.ExtensionData.parse(<String, Object?>{
          '__destinationStream': destinationStream,
          'customField': 'abc',
        }),
      );

      mockVmService.emitEvent(vm.EventStreams.kExtension, extensionEvent);

      final received = await eventCompleter.future;
      expect(received.extensionKind, 'CustomExt');
      expect(received.extensionData?.data['customField'], 'abc');
      expect(
        received.extensionData?.data.containsKey('__destinationStream'),
        isFalse,
      );
    });

    test('dynamic stream listen and cancel propagates to VM service', () async {
      const dynamicStream = 'DynamicCustomStream';
      await ddsClient.streamListen(dynamicStream);
      expect(mockVmService.listenedStreams, contains(dynamicStream));

      await ddsClient.streamCancel(dynamicStream);
      expect(mockVmService.cancelledStreams, contains(dynamicStream));
    });
  });
}
