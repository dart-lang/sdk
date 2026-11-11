// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service_io.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide LogRecord;
import 'package:vm_service/vm_service_io.dart';

import 'utils/mocks.dart';
import 'utils/utilities.dart';

const _yieldControlToDdsMethod = '_yieldControlToDDS';
const _ddsConnectedEventKind = 'DartDevelopmentServiceConnected';
const _ddsRedirectUri = 'http://127.0.0.1:42673/authToken/';

Future<VmService> _connectTestClient(Uri uri) async {
  final client = await vmServiceConnectUri(uri.toString());
  addTearDown(client.dispose);
  return client;
}

void main() {
  group('$DartDevelopmentServiceManager:', () {
    test('_yieldControlToDDS disconnects multiple clients with service '
        'extensions and active stream subscriptions cleanly', () async {
      final warnings = <LogRecord>[];
      final logSub = Logger.root.onRecord.listen((record) {
        if (record.level >= Level.WARNING) {
          warnings.add(record);
        }
      });
      addTearDown(logSub.cancel);

      late final _DdsBackend backend;
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
        backendBuilder: (frontend) {
          backend = _DdsBackend(frontend: frontend);
          return backend;
        },
      );

      // Mirrors `flutter_attach_test.dart` (`spawnDdsInstance: false`):
      // - `toolClient` (`flutter run --no-dds`) registers service extensions
      //   and subscribes to a single stream (`Extension`), so its cleanup
      //   finishes first and broadcasts `ServiceUnregistered` events.
      // - `driverClient` (`FlutterRunTestDriver`) subscribes to multiple
      //   streams including `Service`, so its connection is already closed by
      //   `_yieldControlToDDS` while its `streamCancel` calls are still in
      //   flight on `_streamSubscriptionMutex`.
      final toolClient = await _connectTestClient(service.uri);
      final driverClient = await _connectTestClient(service.uri);

      await toolClient.streamListen(EventStreams.kExtension);
      const registeredServices = <String>[
        'reloadSources',
        'hotRestart',
        'flutterVersion',
      ];
      for (final serviceName in registeredServices) {
        toolClient.registerServiceCallback(
          serviceName,
          (_) async => <String, Object?>{'result': Success().toJson()},
        );
        await toolClient.registerService(serviceName, 'Flutter Tools');
      }

      final ddsConnectedCompleter = Completer<Event>();
      driverClient.onServiceEvent.listen((event) {
        if (event.kind == _ddsConnectedEventKind &&
            !ddsConnectedCompleter.isCompleted) {
          ddsConnectedCompleter.complete(event);
        }
      });
      await driverClient.streamListen(EventStreams.kIsolate);
      await driverClient.streamListen(EventStreams.kDebug);
      await driverClient.streamListen(EventStreams.kService);

      final ddsClient = await _connectTestClient(service.uri);
      final response = await ddsClient.callMethod(
        _yieldControlToDdsMethod,
        args: <String, Object?>{'uri': _ddsRedirectUri},
      );
      expect(response.type, 'Success');

      final connectedEvent = await ddsConnectedCompleter.future;
      expect(connectedEvent.json?['uri'], _ddsRedirectUri);

      await Future.wait([toolClient.onDone, driverClient.onDone]);
      await pumpEventQueue();

      expect(await backend.ddsManager.ddsConnected, Uri.parse(_ddsRedirectUri));
      expect(
        service.clientConnectionController.redirectUri,
        Uri.parse(_ddsRedirectUri),
      );
      expect(service.clients, hasLength(1));
      expect(service.clients.single.name, 'DDS');
      expect(warnings, isEmpty);

      // Once DDS disconnects, direct connections are accepted again.
      final serverDdsClient = service.clients.single;
      await ddsClient.dispose();
      await ddsClient.onDone;
      await serverDdsClient.done;
      await pumpEventQueue();

      expect(service.clientConnectionController.redirectUri, isNull);
      await _connectTestClient(service.uri);
    });

    test('_yieldControlToDDS succeeds even if a disconnecting client cleanup '
        'throws', () async {
      final warnings = <LogRecord>[];
      final logSub = Logger.root.onRecord.listen((record) {
        if (record.level >= Level.WARNING) {
          warnings.add(record);
        }
      });
      addTearDown(logSub.cancel);

      var throwOnCleanup = true;
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
        backendBuilder: (frontend) => _DdsBackend(
          frontend: frontend,
          onClientCleanup: () async {
            if (throwOnCleanup) {
              throw StateError('Simulated client cleanup failure');
            }
          },
        ),
      );

      final nonDdsClient = await _connectTestClient(service.uri);
      final ddsClient = await _connectTestClient(service.uri);

      final response = await ddsClient.callMethod(
        _yieldControlToDdsMethod,
        args: <String, Object?>{'uri': _ddsRedirectUri},
      );
      expect(response.type, 'Success');
      await nonDdsClient.onDone;
      await pumpEventQueue();

      expect(
        service.clientConnectionController.redirectUri,
        Uri.parse(_ddsRedirectUri),
      );
      expect(service.clients, hasLength(1));
      expect(service.clients.single.name, 'DDS');
      expect(
        warnings.map((r) => r.message),
        contains(contains('Simulated client cleanup failure')),
      );

      throwOnCleanup = false;
      final serverDdsClient = service.clients.single;
      await ddsClient.dispose();
      await ddsClient.onDone;
      await serverDdsClient.done;
      await pumpEventQueue();
      expect(service.clientConnectionController.redirectUri, isNull);
    });

    test('_yieldControlToDDS restores connection acceptance if closing a '
        'non-DDS client throws', () async {
      var throwOnClose = true;
      late final _DdsBackend backend;
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
        backendBuilder: (frontend) {
          backend = _DdsBackend(
            frontend: frontend,
            onClientClose: () async {
              if (throwOnClose) {
                throw StateError('Simulated client close failure');
              }
            },
          );
          return backend;
        },
      );
      addTearDown(() {
        throwOnClose = false;
      });

      final ddsConnectedFuture = backend.ddsManager.ddsConnected;
      final nonDdsClient = await _connectTestClient(service.uri);
      final ddsClient1 = await _connectTestClient(service.uri);

      await expectLater(
        ddsClient1.callMethod(
          _yieldControlToDdsMethod,
          args: <String, Object?>{'uri': _ddsRedirectUri},
        ),
        throwsA(isA<RPCError>()),
      );
      await nonDdsClient.onDone;
      await pumpEventQueue();

      // Connection acceptance must be restored immediately rather than
      // remaining permanently wedged redirecting to the failed DDS URI, and
      // the failed client must not be left named 'DDS'.
      expect(service.clientConnectionController.redirectUri, isNull);
      expect(service.clients.single.name, isNot('DDS'));

      throwOnClose = false;
      final serverDdsClient1 = service.clients.single;
      await ddsClient1.dispose();
      await ddsClient1.onDone;
      await serverDdsClient1.done;
      await pumpEventQueue();
      expect(service.clients, isEmpty);

      // A subsequent DDS connection attempt can now connect and take control,
      // completing pre-existing waiters on `ddsConnected`.
      final ddsClient2 = await _connectTestClient(service.uri);
      final response = await ddsClient2.callMethod(
        _yieldControlToDdsMethod,
        args: <String, Object?>{'uri': _ddsRedirectUri},
      );
      expect(response.type, 'Success');
      expect(await ddsConnectedFuture, Uri.parse(_ddsRedirectUri));
      expect(
        service.clientConnectionController.redirectUri,
        Uri.parse(_ddsRedirectUri),
      );
    });

    test('_yieldControlToDDS restores connection acceptance if DDS disconnects '
        'while closing non-DDS clients', () async {
      final closeStarted = Completer<void>();
      final allowClose = Completer<void>();
      addTearDown(() {
        if (!allowClose.isCompleted) {
          allowClose.complete();
        }
      });

      late final _DdsBackend backend;
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
        backendBuilder: (frontend) {
          backend = _DdsBackend(
            frontend: frontend,
            onClientClose: () async {
              if (!closeStarted.isCompleted) {
                closeStarted.complete();
                await allowClose.future;
              }
            },
          );
          return backend;
        },
      );

      final ddsConnectedFuture = backend.ddsManager.ddsConnected;
      var ddsConnectedCompleted = false;
      unawaited(
        ddsConnectedFuture.then((_) {
          ddsConnectedCompleted = true;
        }),
      );

      final nonDdsClient = await _connectTestClient(service.uri);
      final serverNonDdsClient = service.clients.single;
      final ddsClient1 = await _connectTestClient(service.uri);
      final serverDdsClient1 = service.clients.singleWhere(
        (c) => c != serverNonDdsClient,
      );

      final yieldFuture = expectLater(
        ddsClient1.callMethod(
          _yieldControlToDdsMethod,
          args: <String, Object?>{'uri': _ddsRedirectUri},
        ),
        throwsA(isA<RPCError>()),
      );
      await closeStarted.future;

      // Disconnect the incoming DDS client before `nonDdsClient.close()`
      // finishes.
      await ddsClient1.dispose();
      await ddsClient1.onDone;
      await serverDdsClient1.done;
      await pumpEventQueue();

      allowClose.complete();
      await yieldFuture;
      await nonDdsClient.onDone;
      await pumpEventQueue();

      expect(ddsConnectedCompleted, isFalse);
      expect(service.clientConnectionController.redirectUri, isNull);
      expect(service.clients, isEmpty);

      // A subsequent DDS connection can still take control and complete
      // pre-existing waiters on `ddsConnected`.
      final ddsClient2 = await _connectTestClient(service.uri);
      final response = await ddsClient2.callMethod(
        _yieldControlToDdsMethod,
        args: <String, Object?>{'uri': _ddsRedirectUri},
      );
      expect(response.type, 'Success');
      expect(await ddsConnectedFuture, Uri.parse(_ddsRedirectUri));
    });
  });
}

final class _DdsBackend extends FakeDartRuntimeServiceBackend {
  _DdsBackend({
    required super.frontend,
    this.onClientCleanup,
    this.onClientClose,
  }) : ddsManager = DartDevelopmentServiceManager(
         frontend: frontend,
         launchOnStart: false,
         printDtd: false,
         host: InternetAddress.loopbackIPv4.host,
         port: 0,
       );

  final DartDevelopmentServiceManager ddsManager;
  final Future<void> Function()? onClientCleanup;
  final Future<void> Function()? onClientClose;

  @override
  late final rpcs = UnmodifiableListView<ServiceRpcHandler>(ddsManager.rpcs);

  @override
  ClientManager<DartRuntimeServiceBackend> clientManagerBuilder() {
    return _HookedClientManager(
      backend: this,
      eventStreamMethods: frontend.eventStreams,
      onClientCleanup: onClientCleanup,
      onClientClose: onClientClose,
    );
  }
}

final class _HookedClient extends Client {
  _HookedClient({
    required super.artificial,
    required super.backend,
    required super.clientManager,
    required super.clients,
    required super.connection,
    required super.eventStreamMethods,
    super.name,
    this.onClientCleanup,
    this.onClientClose,
  });

  final Future<void> Function()? onClientCleanup;
  final Future<void> Function()? onClientClose;

  @override
  Future<void> close() async {
    await super.close();
    await onClientClose?.call();
  }

  @override
  @protected
  Future<void> cleanup() async {
    await super.cleanup();
    await onClientCleanup?.call();
  }
}

final class _HookedClientManager extends ClientManager {
  _HookedClientManager({
    required super.backend,
    required super.eventStreamMethods,
    this.onClientCleanup,
    this.onClientClose,
  });

  final Future<void> Function()? onClientCleanup;
  final Future<void> Function()? onClientClose;

  @override
  Client clientBuilder({
    required bool artificial,
    required DartRuntimeServiceBackend backend,
    required UnmodifiableClientNamedLookup clients,
    required StreamChannel<Object?> connection,
    required EventStreamMethods eventStreamMethods,
    String? name,
  }) {
    return _HookedClient(
      artificial: artificial,
      backend: backend,
      clientManager: this,
      clients: clients,
      connection: connection,
      eventStreamMethods: eventStreamMethods,
      name: name,
      onClientCleanup: onClientCleanup,
      onClientClose: onClientClose,
    );
  }
}
