// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/src/dart_runtime_service_options.dart';
import 'package:dart_runtime_service/src/dart_runtime_service_rpcs.dart';
import 'package:dart_runtime_service/src/event_streams.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'utils/matchers.dart';
import 'utils/utilities.dart';

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
  });
}
