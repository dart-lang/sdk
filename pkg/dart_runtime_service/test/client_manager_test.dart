// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'utils/utilities.dart';

void main() {
  group('ClientManager:', () {
    const testMethod = 'someMethod';
    const testNotification = 'someNotification';

    late DartRuntimeService service;
    late ClientManager manager;

    setUp(() async {
      service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );
      manager = service.clientManager;
    });

    test('findFirstClientThatHandlesService', () {
      const serviceName = 's1';

      expect(manager.findFirstClientThatHandlesService(serviceName), isNull);

      final controller1 = StreamChannelController<String>();
      final client1 = manager.addClient(connection: controller1.foreign);
      client1.registerService(service: serviceName, alias: 'Service 1');

      expect(
        manager.findFirstClientThatHandlesService(serviceName),
        equals(client1),
      );
    });

    Future<
      ({
        Client client,
        StreamController<Object?> incoming,
        List<LogRecord> warnings,
        List<Object> zoneErrors,
      })
    >
    createHalfClosedClient() async {
      final warnings = <LogRecord>[];
      final logSub = Logger.root.onRecord.listen((record) {
        if (record.level >= Level.WARNING) {
          warnings.add(record);
        }
      });
      addTearDown(logSub.cancel);

      final incoming = StreamController<Object?>();
      addTearDown(incoming.close);
      final outgoing = StreamController<Object?>()..stream.listen((_) {});
      final zoneErrors = <Object>[];

      late final Client client;
      runZonedGuarded(
        () {
          client = manager.addClient(
            connection: StreamChannel<Object?>(incoming.stream, outgoing.sink),
          );
        },
        (error, _) {
          zoneErrors.add(error);
        },
      );

      // Close only the outgoing sink while keeping incoming stream open so
      // `_clientPeer.isClosed` remains false.
      await outgoing.close();
      expect(manager.clients, contains(client));
      return (
        client: client,
        incoming: incoming,
        warnings: warnings,
        zoneErrors: zoneErrors,
      );
    }

    test(
      'Client sendRequest on closed channel throws '
      'RpcException.serviceDisappeared while notifications are ignored',
      () async {
        final controller = StreamChannelController<String>();
        final client = manager.addClient(connection: controller.foreign);

        // Close the channel to simulate disconnection.
        await controller.local.sink.close();
        await client.done;

        await expectLater(
          client.sendRequest(method: testMethod),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (e) => e.code,
              'code',
              equals(RpcException.serviceDisappeared.code),
            ),
          ),
        );
        expect(
          () => client.sendNotification(method: testNotification),
          returnsNormally,
        );
        expect(
          () => client.sendBinaryData(data: Uint8List.fromList(const <int>[1])),
          returnsNormally,
        );
      },
    );

    test('sendNotification on half-closed sink closes client without uncaught '
        'errors', () async {
      final (:client, incoming: _, :warnings, :zoneErrors) =
          await createHalfClosedClient();

      expect(
        () => client.sendNotification(method: testNotification),
        returnsNormally,
      );
      await client.done;
      await pumpEventQueue();

      expect(manager.clients, isEmpty);
      expect(zoneErrors, isEmpty);
      expect(warnings, isEmpty);
    });

    test(
      'sendRequest on half-closed sink throws RpcException.serviceDisappeared '
      'and closes client',
      () async {
        final (:client, incoming: _, :warnings, :zoneErrors) =
            await createHalfClosedClient();

        await expectLater(
          client.sendRequest(method: testMethod),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (e) => e.code,
              'code',
              equals(RpcException.serviceDisappeared.code),
            ),
          ),
        );
        await client.done;
        await pumpEventQueue();

        expect(manager.clients, isEmpty);
        expect(zoneErrors, isEmpty);
        expect(warnings, isEmpty);
      },
    );

    test('sendBinaryData on half-closed sink closes client without uncaught '
        'errors', () async {
      final (:client, incoming: _, :warnings, :zoneErrors) =
          await createHalfClosedClient();

      expect(
        () => client.sendBinaryData(data: Uint8List.fromList(const <int>[1])),
        returnsNormally,
      );
      await client.done;
      await pumpEventQueue();

      expect(manager.clients, isEmpty);
      expect(zoneErrors, isEmpty);
      expect(warnings, isEmpty);
    });

    test('outgoing RPC response on half-closed sink closes client without '
        'uncaught errors', () async {
      const getClientNameRequest =
          '{"jsonrpc":"2.0","id":"1","method":"getClientName"}';
      final (:client, :incoming, :warnings, :zoneErrors) =
          await createHalfClosedClient();

      incoming.add(getClientNameRequest);
      await client.done;
      await pumpEventQueue();

      expect(manager.clients, isEmpty);
      expect(zoneErrors, isEmpty);
      expect(warnings, isEmpty);
    });

    test(
      'close ignores synchronous StateError from connection.sink.close',
      () async {
        final warnings = <LogRecord>[];
        final logSub = Logger.root.onRecord.listen((record) {
          if (record.level >= Level.WARNING) {
            warnings.add(record);
          }
        });
        addTearDown(logSub.cancel);

        final incoming = StreamController<Object?>();
        addTearDown(incoming.close);
        final sink = _CustomCloseSink(
          onClose: () => throw StateError('Sink cannot be closed'),
        );
        final zoneErrors = <Object>[];

        late final Client client;
        runZonedGuarded(
          () {
            client = manager.addClient(
              connection: StreamChannel<Object?>(incoming.stream, sink),
            );
          },
          (error, _) {
            zoneErrors.add(error);
          },
        );

        await client.close();
        await pumpEventQueue();

        expect(manager.clients, isEmpty);
        expect(zoneErrors, isEmpty);
        expect(warnings, isEmpty);
      },
    );

    test(
      'close ignores asynchronous error from connection.sink.close',
      () async {
        final warnings = <LogRecord>[];
        final logSub = Logger.root.onRecord.listen((record) {
          if (record.level >= Level.WARNING) {
            warnings.add(record);
          }
        });
        addTearDown(logSub.cancel);

        final incoming = StreamController<Object?>();
        addTearDown(incoming.close);
        final sink = _CustomCloseSink(
          onClose: () => Future<void>.error(StateError('Async sink close')),
        );
        final zoneErrors = <Object>[];

        late final Client client;
        runZonedGuarded(
          () {
            client = manager.addClient(
              connection: StreamChannel<Object?>(incoming.stream, sink),
            );
          },
          (error, _) {
            zoneErrors.add(error);
          },
        );

        await client.close();
        await pumpEventQueue();

        expect(manager.clients, isEmpty);
        expect(zoneErrors, isEmpty);
        expect(warnings, isEmpty);
      },
    );

    test('onClientNameChanged is called on client.setName', () {
      var callbackInvoked = false;
      String? oldNameParam;
      String? newNameParam;

      final testManager = TestClientManager(
        backend: manager.backend,
        eventStreamMethods: manager.eventStreamMethods,
        onNameChanged: (c, oldName, newName) {
          callbackInvoked = true;
          oldNameParam = oldName;
          newNameParam = newName;
        },
      );

      final controller2 = StreamChannelController<String>();
      final testClient = testManager.addClient(connection: controller2.foreign);
      final testClientInitialName = testClient.name;
      const newName = 'customName';
      testClient.setName(newName);

      expect(callbackInvoked, isTrue);
      expect(oldNameParam, equals(testClientInitialName));
      expect(newNameParam, equals(newName));
    });

    test('shutdown awaits client cleanup before completing', () async {
      var cleanupCompleted = false;
      final testManager = TestClientManager(
        backend: manager.backend,
        eventStreamMethods: manager.eventStreamMethods,
        onCleanup: () async {
          await Future<void>.value();
          cleanupCompleted = true;
        },
        onNameChanged: (_, _, _) {},
      );

      final controller = StreamChannelController<String>();
      testManager.addClient(connection: controller.foreign);

      await testManager.shutdown();
      expect(cleanupCompleted, isTrue);
    });

    test('disconnect removes client even when cleanup throws', () async {
      final warnings = <LogRecord>[];
      final logSub = Logger.root.onRecord.listen((record) {
        if (record.level >= Level.WARNING) {
          warnings.add(record);
        }
      });
      addTearDown(logSub.cancel);

      final testManager = TestClientManager(
        backend: manager.backend,
        eventStreamMethods: manager.eventStreamMethods,
        onCleanup: () => Future<void>.error(StateError('Cleanup failure')),
        onNameChanged: (_, _, _) {},
      );

      final controller = StreamChannelController<String>();
      testManager.addClient(connection: controller.foreign);
      expect(testManager.clients, hasLength(1));

      await controller.local.sink.close();
      await pumpEventQueue();

      expect(testManager.clients, isEmpty);
      expect(
        warnings.map((r) => r.message),
        contains(contains('Cleanup failure')),
      );
    });
  });
}

final class TestClient extends Client {
  TestClient({
    required super.artificial,
    required super.backend,
    required super.clientManager,
    required super.clients,
    required super.connection,
    required super.eventStreamMethods,
    super.name,
    this.onCleanup,
  });

  final Future<void> Function()? onCleanup;

  @override
  @protected
  Future<void> cleanup() async {
    await super.cleanup();
    await onCleanup?.call();
  }
}

final class TestClientManager extends ClientManager {
  TestClientManager({
    required super.backend,
    required super.eventStreamMethods,
    required this.onNameChanged,
    this.onCleanup,
  });

  final Future<void> Function()? onCleanup;
  final void Function(Client client, String oldName, String newName)
  onNameChanged;

  @override
  Client clientBuilder({
    required bool artificial,
    required DartRuntimeServiceBackend backend,
    required UnmodifiableClientNamedLookup clients,
    required StreamChannel<Object?> connection,
    required EventStreamMethods eventStreamMethods,
    String? name,
  }) {
    return TestClient(
      artificial: artificial,
      backend: backend,
      clientManager: this,
      clients: clients,
      connection: connection,
      eventStreamMethods: eventStreamMethods,
      name: name,
      onCleanup: onCleanup,
    );
  }

  @override
  void onClientNameChanged(
    Client client, {
    required String oldName,
    required String newName,
  }) {
    onNameChanged(client, oldName, newName);
  }
}

final class _CustomCloseSink implements StreamSink<Object?> {
  _CustomCloseSink({required this.onClose});

  final Future<void> Function() onClose;
  final _doneCompleter = Completer<void>();

  @override
  void add(Object? event) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<Object?> stream) => stream.drain<void>();

  @override
  Future<void> close() => onClose();

  @override
  Future<void> get done => _doneCompleter.future;
}
