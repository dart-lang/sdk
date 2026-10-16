// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_runtime_service/src/dart_runtime_service_options.dart';
import 'package:dart_runtime_service/src/dart_runtime_service_rpcs.dart';
import 'package:dart_runtime_service/src/event_streams.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'utils/matchers.dart';
import 'utils/mocks.dart';
import 'utils/utilities.dart';

final class _DelayedStreamListenBackend extends FakeDartRuntimeServiceBackend {
  _DelayedStreamListenBackend({required super.frontend});

  final onStreamListenCompleters = <String, Completer<bool>>{};
  final onStreamListenCountByStream = <String, int>{};
  final onStreamListenWaiters = <String, Map<int, Completer<void>>>{};

  Future<void> waitForListenCount(String streamId, int count) {
    final waiters = onStreamListenWaiters.putIfAbsent(
      streamId,
      () => <int, Completer<void>>{},
    );
    final completer = waiters.putIfAbsent(count, Completer<void>.new);
    if ((onStreamListenCountByStream[streamId] ?? 0) >= count &&
        !completer.isCompleted) {
      completer.complete();
    }
    return completer.future;
  }

  @override
  Future<bool> onStreamListen({
    required String streamId,
    required Map<String, Object?> params,
  }) {
    final count = (onStreamListenCountByStream[streamId] ?? 0) + 1;
    onStreamListenCountByStream[streamId] = count;
    final waiter = onStreamListenWaiters[streamId]?[count];
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
    final completer = onStreamListenCompleters[streamId];
    if (completer != null) {
      return completer.future;
    }
    return Future<bool>.value(true);
  }
}

final class HelloWorldEvent extends StreamEvent {
  HelloWorldEvent() : super(streamId: kStreamId, kind: kKind);

  static const kStreamId = 'CustomStream';
  static const kKind = 'hello_world';

  @override
  Map<String, Object?> toJson() {
    return {
      StreamEvent.kStreamId: streamId,
      StreamEvent.kEvent: Event(kind: kind, timestamp: timestamp).toJson(),
    };
  }
}

void main() {
  group('$DartRuntimeServiceRpcs:', () {
    test('streamListen + streamCancel', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());
      final completer = Completer<void>();

      // Register a listener for events on kStreamId.
      client.onEvent(HelloWorldEvent.kStreamId).listen((event) {
        expect(event.kind, HelloWorldEvent.kKind);
        completer.complete();
      });

      // Verify the stream has been subscribed to.
      await client.streamListen(HelloWorldEvent.kStreamId);
      expect(
        service.eventStreamManager.streamListeners[HelloWorldEvent.kStreamId],
        isNotEmpty,
      );

      // Post an event to the stream and wait for the client to receive it.
      HelloWorldEvent().send(eventStreamMethods: service.eventStreamManager);
      await completer.future;

      // Verify the stream has no listeners after the client cancels its
      // subscription.
      await client.streamCancel(HelloWorldEvent.kStreamId);
      expect(
        service.eventStreamManager.streamListeners[HelloWorldEvent.kStreamId],
        isEmpty,
      );
    });

    test('streamListen already subscribed', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());

      // Verify the stream has been subscribed to.
      await client.streamListen(HelloWorldEvent.kStreamId);
      expect(
        service.eventStreamManager.streamListeners[HelloWorldEvent.kStreamId],
        isNotEmpty,
      );

      // Listening to a stream that's already subscribed to results in an RPC
      // error being returned by the service.
      expect(
        () async => await client.streamListen(HelloWorldEvent.kStreamId),
        throwsStreamAlreadySubscribedRPCError,
      );
    });

    test('streamCancel stream with no subscription', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());

      // Cancelling a stream that's not subscribed to results in an RPC error
      // being returned by the service.
      expect(
        () async => await client.streamCancel(HelloWorldEvent.kStreamId),
        throwsStreamNotSubscribedRPCError,
      );
    });

    test('hasListeners returns true when subscribed', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());
      expect(
        service.eventStreamManager.hasListeners(HelloWorldEvent.kStreamId),
        isFalse,
      );

      await client.streamListen(HelloWorldEvent.kStreamId);
      expect(
        service.eventStreamManager.hasListeners(HelloWorldEvent.kStreamId),
        isTrue,
      );

      await client.streamCancel(HelloWorldEvent.kStreamId);
      expect(
        service.eventStreamManager.hasListeners(HelloWorldEvent.kStreamId),
        isFalse,
      );
    });

    test('Service stream catch-up on streamListen', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client1 = await vmServiceConnectUri(service.uri.toString());
      await client1.streamListen(EventStreams.kService);

      var client1ServiceRegisteredEventCount = 0;
      client1.onServiceEvent.listen((event) {
        if (event.kind == EventKind.kServiceRegistered) {
          client1ServiceRegisteredEventCount++;
        }
      });

      const serviceName = 'testService';
      const serviceAlias = 'testAlias';

      client1.registerServiceCallback(
        serviceName,
        (params) async => <String, dynamic>{},
      );
      await client1.registerService(serviceName, serviceAlias);

      final client2 = await vmServiceConnectUri(service.uri.toString());
      final client2EventCompleter = Completer<Event>();

      client2.onServiceEvent.listen((event) {
        if (event.kind == EventKind.kServiceRegistered &&
            event.service == serviceName) {
          client2EventCompleter.complete(event);
        }
      });

      await client2.streamListen(EventStreams.kService);
      final event = await client2EventCompleter.future;

      // client1 receives 0 ServiceRegistered events for its own service
      // registration.
      expect(client1ServiceRegisteredEventCount, equals(0));

      // client2 receives 1 ServiceRegistered event on catch-up when
      // subscribing.
      expect(event.kind, EventKind.kServiceRegistered);
      expect(event.service, serviceName);
      expect(event.alias, serviceAlias);

      // Verify client1 did not receive a duplicate event when client2
      // subscribed.
      await pumpEventQueue();
      expect(client1ServiceRegisteredEventCount, equals(0));
    });

    test(
      'concurrent streamListen for the same stream waits for onStreamListen',
      () async {
        late final _DelayedStreamListenBackend backend;
        final service = await createDartRuntimeServiceForTest(
          config: const DartRuntimeServiceOptions(enableLogging: true),
          backendBuilder: (frontend) {
            backend = _DelayedStreamListenBackend(frontend: frontend);
            backend.onStreamListenCompleters[HelloWorldEvent.kStreamId] =
                Completer<bool>();
            return backend;
          },
        );

        final client1 = await vmServiceConnectUri(service.uri.toString());
        final client2 = await vmServiceConnectUri(service.uri.toString());

        var listen1Completed = false;
        final listen1 = client1
            .streamListen(HelloWorldEvent.kStreamId)
            .then((_) => listen1Completed = true);
        await backend.waitForListenCount(HelloWorldEvent.kStreamId, 1);

        var listen2Completed = false;
        final listen2 = client2
            .streamListen(HelloWorldEvent.kStreamId)
            .then((_) => listen2Completed = true);
        await backend.waitForListenCount(HelloWorldEvent.kStreamId, 2);

        expect(listen1Completed, isFalse);
        expect(listen2Completed, isFalse);

        // Subscriptions to other streams should not be blocked by the in-flight
        // subscription on HelloWorldEvent.kStreamId.
        await client1.streamListen(EventStreams.kService);
        expect(backend.onStreamListenCountByStream[EventStreams.kService], 1);

        backend.onStreamListenCompleters[HelloWorldEvent.kStreamId]!.complete(
          true,
        );
        await Future.wait([listen1, listen2]);

        expect(listen1Completed, isTrue);
        expect(listen2Completed, isTrue);
        expect(
          service
              .eventStreamManager
              .streamListeners[HelloWorldEvent.kStreamId]
              ?.length,
          2,
        );
      },
    );

    test('concurrent streamListen for the same invalid stream fails for all '
        'callers', () async {
      late final _DelayedStreamListenBackend backend;
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
        backendBuilder: (frontend) {
          backend = _DelayedStreamListenBackend(frontend: frontend);
          backend.onStreamListenCompleters[HelloWorldEvent.kStreamId] =
              Completer<bool>();
          return backend;
        },
      );

      final client1 = await vmServiceConnectUri(service.uri.toString());
      final client2 = await vmServiceConnectUri(service.uri.toString());

      final listen1 = expectLater(
        client1.streamListen(HelloWorldEvent.kStreamId),
        throwsInvalidParamsRPCError,
      );
      await backend.waitForListenCount(HelloWorldEvent.kStreamId, 1);

      final listen2 = expectLater(
        client2.streamListen(HelloWorldEvent.kStreamId),
        throwsInvalidParamsRPCError,
      );
      await backend.waitForListenCount(HelloWorldEvent.kStreamId, 2);

      backend.onStreamListenCompleters[HelloWorldEvent.kStreamId]!.complete(
        false,
      );
      await Future.wait([listen1, listen2]);

      expect(
        service.eventStreamManager.streamListeners[HelloWorldEvent.kStreamId],
        isNull,
      );
    });

    test('BinaryStreamEvent.fromData parses streamId and payload', () {
      final header = json.encode(<String, Object?>{
        'jsonrpc': '2.0',
        'method': 'streamNotify',
        'params': <String, Object?>{
          'streamId': 'BinaryStream',
          'event': <String, Object?>{
            'type': 'Event',
            'kind': 'BinaryData',
            'timestamp': 123456789,
          },
        },
      });
      final headerBytes = utf8.encode(header);
      const metadataOffset = 4;
      final dataOffset = metadataOffset + headerBytes.length;
      final payload = <int>[10, 20, 30, 40];
      final buffer = Uint8List(dataOffset + payload.length);
      final byteData = ByteData.view(buffer.buffer);
      byteData.setUint32(0, dataOffset, Endian.little);
      buffer.setRange(metadataOffset, dataOffset, headerBytes);
      buffer.setRange(dataOffset, buffer.length, payload);

      final event = BinaryStreamEvent.fromData(buffer);
      expect(event.streamId, equals('BinaryStream'));
      expect(event.data, equals(buffer));
    });
  });
}
