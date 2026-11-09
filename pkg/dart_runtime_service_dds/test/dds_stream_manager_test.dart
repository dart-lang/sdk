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

const _kDestinationStreamKey = '__destinationStream';
const _kIncludePrivateMembersKey = '_includePrivateMembers';
const _kIncludePrivateMembersParam = 'includePrivateMembers';
const _kSetStreamIncludePrivateMembersRpc = '_setStreamIncludePrivateMembers';
const _kStreamIdParam = 'streamId';

class MockVmService {
  MockVmService._(
    this.server,
    this.port, {
    this.onStreamListen,
    Set<String>? unsupportedStreams,
  }) : unsupportedStreams = unsupportedStreams ?? <String>{};

  final HttpServer server;
  final int port;
  final clients = <json_rpc.Peer>[];
  final listenedStreams = <String>{};
  final streamListenCounts = <String, int>{};
  final cancelledStreams = <String>{};
  final privateMemberCalls = <String, bool>{};
  final Set<String> unsupportedStreams;
  FutureOr<void> Function(MockVmService mock, String streamId)? onStreamListen;

  /// Invoked when `_setStreamIncludePrivateMembers` is called for a stream.
  void Function(String streamId)? onSetStreamIncludePrivateMembers;

  Uri get uri => Uri.parse('http://localhost:$port/');

  static Future<MockVmService> start({
    FutureOr<void> Function(MockVmService mock, String streamId)?
    onStreamListen,
    Set<String>? unsupportedStreams,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = MockVmService._(
      server,
      server.port,
      onStreamListen: onStreamListen,
      unsupportedStreams: unsupportedStreams,
    );

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

      peer.registerMethod('streamListen', (json_rpc.Parameters params) async {
        final streamId = params[_kStreamIdParam].asString;
        if (mock.unsupportedStreams.contains(streamId)) {
          throw json_rpc.RpcException.invalidParams(
            "streamListen: invalid 'streamId' parameter: $streamId",
          );
        }
        mock.listenedStreams.add(streamId);
        mock.streamListenCounts[streamId] =
            (mock.streamListenCounts[streamId] ?? 0) + 1;
        await mock.onStreamListen?.call(mock, streamId);
        return vm.Success().toJson();
      });

      peer.registerMethod('streamCancel', (json_rpc.Parameters params) {
        final streamId = params[_kStreamIdParam].asString;
        mock.cancelledStreams.add(streamId);
        return vm.Success().toJson();
      });

      peer.registerMethod(_kSetStreamIncludePrivateMembersRpc, (
        json_rpc.Parameters params,
      ) {
        final streamId = params[_kStreamIdParam].asString;
        final includePrivateMembers =
            params[_kIncludePrivateMembersParam].asBool;
        mock.privateMemberCalls[streamId] = includePrivateMembers;
        mock.onSetStreamIncludePrivateMembers?.call(streamId);
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
        equals(<String>{
          vm.EventStreams.kDebug,
          vm.EventStreams.kIsolate,
          vm.EventStreams.kLogging,
          vm.EventStreams.kStdout,
          vm.EventStreams.kStderr,
          vm.EventStreams.kExtension,
          vm.EventStreams.kTimer,
        }),
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
      'postEvent rejects core and unsubscribed streams and broadcasts custom '
      'events',
      () async {
        final streamManager = backend.streamManager;

        await ddsClient.streamListen(vm.EventStreams.kService);
        await ddsClient.streamListen(vm.EventStreams.kProfiler);
        for (final coreStream in <String>[
          vm.EventStreams.kLogging,
          vm.EventStreams.kService,
          vm.EventStreams.kProfiler,
          vm.EventStreams.kGC,
          vm.EventStreams.kHeapSnapshot,
          vm.EventStreams.kTimeline,
          vm.EventStreams.kVM,
          '_Echo',
        ]) {
          expect(
            () => streamManager.postEvent(
              coreStream,
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
        }

        const customStream = 'CustomStream';
        expect(
          () => streamManager.postEvent(
            customStream,
            'CustomKind',
            <String, Object?>{},
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (e) => e.code,
              'code',
              vm.RPCErrorKind.kCustomStreamDoesNotExist.code,
            ),
          ),
        );

        final firstEventFuture = ddsClient.onEvent(customStream).first;
        await ddsClient.streamListen(customStream);

        streamManager.postEvent(customStream, 'CustomKind', <String, Object?>{
          'key': 'value',
        });

        final received = await firstEventFuture;
        expect(received.extensionKind, 'CustomKind');
        expect(received.extensionData?.data['key'], 'value');

        // Canceling the subscription should cause postEvent to throw
        // kCustomStreamDoesNotExist when no other listeners remain.
        await ddsClient.streamCancel(customStream);
        expect(
          () => streamManager.postEvent(
            customStream,
            'CustomKind',
            <String, Object?>{},
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (e) => e.code,
              'code',
              vm.RPCErrorKind.kCustomStreamDoesNotExist.code,
            ),
          ),
        );

        // Re-subscribing should allow events to be posted again.
        final resubscribedEventFuture = ddsClient.onEvent(customStream).first;
        await ddsClient.streamListen(customStream);
        streamManager.postEvent(customStream, 'CustomKind', <String, Object?>{
          'key': 'resubscribed',
        });

        final resubscribedEvent = await resubscribedEventFuture;
        expect(resubscribedEvent.extensionKind, 'CustomKind');
        expect(resubscribedEvent.extensionData?.data['key'], 'resubscribed');
        await ddsClient.streamCancel(customStream);

        // Disconnecting the sole listening client should clean up its stream
        // subscription so postEvent throws kCustomStreamDoesNotExist until a
        // client reconnects and subscribes again.
        final secondClient = await vmServiceConnectUri(
          ddsService.uri.toString(),
        );
        addTearDown(secondClient.dispose);
        final secondClientEventFuture = secondClient
            .onEvent(customStream)
            .first;
        await secondClient.streamListen(customStream);
        final serverClient = ddsService.clients.last;

        streamManager.postEvent(customStream, 'CustomKind', <String, Object?>{
          'key': 'secondClient',
        });
        final secondClientEvent = await secondClientEventFuture;
        expect(secondClientEvent.extensionData?.data['key'], 'secondClient');

        await secondClient.dispose();
        await serverClient.done;

        expect(
          () => streamManager.postEvent(
            customStream,
            'CustomKind',
            <String, Object?>{},
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (e) => e.code,
              'code',
              vm.RPCErrorKind.kCustomStreamDoesNotExist.code,
            ),
          ),
        );

        final reconnectedClient = await vmServiceConnectUri(
          ddsService.uri.toString(),
        );
        addTearDown(reconnectedClient.dispose);
        final reconnectedEventFuture = reconnectedClient
            .onEvent(customStream)
            .first;
        await reconnectedClient.streamListen(customStream);
        final reconnectedServerClient = ddsService.clients.last;

        streamManager.postEvent(customStream, 'CustomKind', <String, Object?>{
          'key': 'reconnected',
        });
        final reconnectedEvent = await reconnectedEventFuture;
        expect(reconnectedEvent.extensionData?.data['key'], 'reconnected');
        await reconnectedClient.dispose();
        await reconnectedServerClient.done;
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
          _kDestinationStreamKey: destinationStream,
          'customField': 'abc',
        }),
      );

      mockVmService.emitEvent(vm.EventStreams.kExtension, extensionEvent);

      final received = await eventCompleter.future;
      expect(received.extensionKind, 'CustomExt');
      expect(received.extensionData?.data['customField'], 'abc');
      expect(
        received.extensionData?.data.containsKey(_kDestinationStreamKey),
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

    test('initializes loggingRepositories unconditionally and captures events '
        'emitted during streamListen handshake', () async {
      final handshakeEvent = vm.Event(
        kind: vm.EventKind.kLogging,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        logRecord: vm.LogRecord(
          message: vm.InstanceRef(
            id: 'objects/handshake-msg',
            kind: vm.InstanceKind.kString,
            valueAsString: 'handshake logging',
          ),
          time: 0,
          level: 0,
          sequenceNumber: 1,
          loggerName: vm.InstanceRef(
            id: 'objects/handshake-logger',
            kind: vm.InstanceKind.kString,
            valueAsString: 'handshake',
          ),
        ),
      );

      final customMockVm = await MockVmService.start(
        unsupportedStreams: <String>{
          vm.EventStreams.kTimer,
          vm.EventStreams.kStdout,
          vm.EventStreams.kStderr,
        },
        onStreamListen: (mock, streamId) {
          if (streamId == vm.EventStreams.kLogging) {
            mock.emitEvent(vm.EventStreams.kLogging, handshakeEvent);
          }
        },
      );
      addTearDown(customMockVm.shutdown);

      late DartRuntimeServiceDdsBackend customBackend;
      final customDdsService = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => customBackend =
            DartRuntimeServiceDdsBackend(customMockVm.uri, frontend: frontend),
      );
      addTearDown(customDdsService.shutdown);

      final streamManager = customBackend.streamManager;
      expect(streamManager.getStreamHistory(vm.EventStreams.kTimer), isEmpty);
      expect(streamManager.getStreamHistory(vm.EventStreams.kStdout), isEmpty);
      expect(streamManager.getStreamHistory(vm.EventStreams.kStderr), isEmpty);

      final loggingHistory = streamManager.getStreamHistory(
        vm.EventStreams.kLogging,
      );
      expect(loggingHistory, isNotNull);
      expect(loggingHistory, hasLength(1));
    });

    test('forwards _setStreamIncludePrivateMembers for core streams and '
        'subsequent client subscriptions', () async {
      await ddsClient.callMethod(
        'streamListen',
        args: <String, Object?>{
          _kStreamIdParam: vm.EventStreams.kDebug,
          _kIncludePrivateMembersKey: true,
        },
      );
      expect(mockVmService.privateMemberCalls[vm.EventStreams.kDebug], isTrue);

      await ddsClient.streamListen(vm.EventStreams.kProfiler);
      expect(
        mockVmService.privateMemberCalls.containsKey(vm.EventStreams.kProfiler),
        isFalse,
      );

      final secondClient = await vmServiceConnectUri(ddsService.uri.toString());
      addTearDown(secondClient.dispose);

      await secondClient.callMethod(
        'streamListen',
        args: <String, Object?>{
          _kStreamIdParam: vm.EventStreams.kProfiler,
          _kIncludePrivateMembersKey: true,
        },
      );
      expect(
        mockVmService.privateMemberCalls[vm.EventStreams.kProfiler],
        isTrue,
      );
    });

    test('forwards _setStreamIncludePrivateMembers for the first listener of '
        'a non-core stream', () async {
      await ddsClient.callMethod(
        'streamListen',
        args: <String, Object?>{
          _kStreamIdParam: vm.EventStreams.kGC,
          _kIncludePrivateMembersKey: false,
        },
      );
      expect(mockVmService.listenedStreams, contains(vm.EventStreams.kGC));
      expect(mockVmService.privateMemberCalls[vm.EventStreams.kGC], isFalse);
    });

    test('does not duplicate stream history for events sent while forwarding '
        '_setStreamIncludePrivateMembers', () async {
      vm.Event stdoutEvent(String bytes) => vm.Event(
        kind: vm.EventKind.kWriteEvent,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        bytes: bytes,
      );

      final streamManager = backend.streamManager;
      mockVmService.emitEvent(vm.EventStreams.kStdout, stdoutEvent('E1'));
      while (streamManager.getStreamHistory(vm.EventStreams.kStdout)!.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      mockVmService.onSetStreamIncludePrivateMembers = (streamId) {
        if (streamId == vm.EventStreams.kStdout) {
          mockVmService.emitEvent(vm.EventStreams.kStdout, stdoutEvent('E2'));
        }
      };

      final received = <String>[];
      final secondEventCompleter = Completer<void>();
      ddsClient.onStdoutEvent.listen((event) {
        received.add(event.bytes!);
        if (received.length == 2) {
          secondEventCompleter.complete();
        }
      });
      await ddsClient.callMethod(
        'streamListen',
        args: <String, Object?>{
          _kStreamIdParam: vm.EventStreams.kStdout,
          _kIncludePrivateMembersKey: true,
        },
      );
      await secondEventCompleter.future;
      // Allow any duplicated events to arrive before checking.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(received, <String>['E1', 'E2']);
    });

    test('drops extension events with __destinationStream targeting core or '
        'unsubscribed streams', () async {
      final stdoutEvents = <vm.Event>[];
      final serviceEvents = <vm.Event>[];
      final extensionEvents = <vm.Event>[];

      final stdoutSub = ddsClient.onStdoutEvent.listen(stdoutEvents.add);
      final serviceSub = ddsClient.onServiceEvent.listen(serviceEvents.add);
      final extensionCompleter = Completer<vm.Event>();
      final extensionSub = ddsClient.onExtensionEvent.listen((event) {
        extensionEvents.add(event);
        if (!extensionCompleter.isCompleted) {
          extensionCompleter.complete(event);
        }
      });
      addTearDown(() async {
        await stdoutSub.cancel();
        await serviceSub.cancel();
        await extensionSub.cancel();
      });

      await ddsClient.streamListen(vm.EventStreams.kStdout);
      await ddsClient.streamListen(vm.EventStreams.kService);
      await ddsClient.streamListen(vm.EventStreams.kExtension);

      mockVmService.emitEvent(
        vm.EventStreams.kExtension,
        vm.Event(
          kind: vm.EventKind.kExtension,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          extensionKind: 'SpoofStdout',
          extensionData: vm.ExtensionData.parse(<String, Object?>{
            _kDestinationStreamKey: vm.EventStreams.kStdout,
            'spoofed': true,
          }),
        ),
      );

      mockVmService.emitEvent(
        vm.EventStreams.kExtension,
        vm.Event(
          kind: vm.EventKind.kExtension,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          extensionKind: 'SpoofService',
          extensionData: vm.ExtensionData.parse(<String, Object?>{
            _kDestinationStreamKey: vm.EventStreams.kService,
            'spoofed': true,
          }),
        ),
      );

      mockVmService.emitEvent(
        vm.EventStreams.kExtension,
        vm.Event(
          kind: vm.EventKind.kExtension,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          extensionKind: 'UnsubscribedCustom',
          extensionData: vm.ExtensionData.parse(<String, Object?>{
            _kDestinationStreamKey: 'UnsubscribedCustomStream',
            'spoofed': true,
          }),
        ),
      );

      mockVmService.emitEvent(
        vm.EventStreams.kExtension,
        vm.Event(
          kind: vm.EventKind.kExtension,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          extensionKind: 'ValidExtension',
          extensionData: vm.ExtensionData.parse(<String, Object?>{
            _kDestinationStreamKey: vm.EventStreams.kExtension,
            'valid': true,
          }),
        ),
      );

      final receivedExtension = await extensionCompleter.future;
      expect(receivedExtension.extensionKind, 'ValidExtension');
      expect(receivedExtension.extensionData?.data['valid'], isTrue);
      expect(
        receivedExtension.extensionData?.data.containsKey(
          _kDestinationStreamKey,
        ),
        isFalse,
      );

      expect(stdoutEvents, isEmpty);
      expect(serviceEvents, isEmpty);
      expect(
        backend.streamManager.getStreamHistory(vm.EventStreams.kStdout),
        isEmpty,
      );
      expect(extensionEvents, hasLength(1));
    });

    test('coalesces concurrent streamListen calls for the same unsubscribed '
        'stream without duplicating events', () async {
      final secondClient = await vmServiceConnectUri(ddsService.uri.toString());
      addTearDown(secondClient.dispose);

      final vmListenStarted = Completer<void>();
      final allowVmListenCompletion = Completer<void>();
      mockVmService.onStreamListen = (mock, streamId) async {
        if (streamId == vm.EventStreams.kProfiler) {
          if (!vmListenStarted.isCompleted) {
            vmListenStarted.complete();
          }
          await allowVmListenCompletion.future;
        }
      };

      final client1Events = <vm.Event>[];
      final client2Events = <vm.Event>[];
      final client1Completer = Completer<void>();
      final client2Completer = Completer<void>();
      final sub1 = ddsClient.onProfilerEvent.listen((event) {
        client1Events.add(event);
        if (!client1Completer.isCompleted) {
          client1Completer.complete();
        }
      });
      final sub2 = secondClient.onProfilerEvent.listen((event) {
        client2Events.add(event);
        if (!client2Completer.isCompleted) {
          client2Completer.complete();
        }
      });
      addTearDown(() async {
        await sub1.cancel();
        await sub2.cancel();
      });

      var listen1Completed = false;
      final listen1 = ddsClient
          .streamListen(vm.EventStreams.kProfiler)
          .then((_) => listen1Completed = true);
      await vmListenStarted.future;

      var listen2Completed = false;
      final listen2 = secondClient
          .streamListen(vm.EventStreams.kProfiler)
          .then((_) => listen2Completed = true);
      await secondClient.callMethod('getClientName');
      await pumpEventQueue();
      expect(listen1Completed, isFalse);
      expect(listen2Completed, isFalse);
      expect(mockVmService.streamListenCounts[vm.EventStreams.kProfiler], 1);

      allowVmListenCompletion.complete();
      await Future.wait([listen1, listen2]);
      expect(listen1Completed, isTrue);
      expect(listen2Completed, isTrue);
      expect(mockVmService.streamListenCounts[vm.EventStreams.kProfiler], 1);

      mockVmService.emitEvent(
        vm.EventStreams.kProfiler,
        vm.Event(
          kind: vm.EventKind.kUserTagChanged,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await Future.wait([client1Completer.future, client2Completer.future]);
      await pumpEventQueue();
      expect(client1Events, hasLength(1));
      expect(client2Events, hasLength(1));
    });

    test('shutdown does not throw ConcurrentModificationError when clients '
        'disconnect concurrently', () async {
      final secondClient = await vmServiceConnectUri(ddsService.uri.toString());
      await secondClient.streamListen(vm.EventStreams.kStdout);
      await secondClient.streamListen(vm.EventStreams.kService);
      await secondClient.streamListen(vm.EventStreams.kProfiler);
      await secondClient.streamListen(vm.EventStreams.kGC);
      await secondClient.streamListen(vm.EventStreams.kTimeline);
      await secondClient.streamListen(vm.EventStreams.kVM);

      await secondClient.dispose();
      await ddsService.shutdown();
    });
  });
}
