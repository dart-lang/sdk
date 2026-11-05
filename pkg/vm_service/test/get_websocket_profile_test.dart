// Copyright (c) 2026, the Dart project authors.
// BSD-style license.
// VMOptions=--timeline_streams=Dart

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_websocket_profile_lib.dart' as testee_lib;

late VmService vmService;

/// Validate one websocket connection.
Future<void> validateConnection(
  String isolateId,
  WebSocketConnectionRef ref,
) async {
  final connection = await vmService.getWebSocketConnection(isolateId, ref.id);

  expect(
    connection,
    isA<WebSocketConnection>()
        .having((c) => c.id, 'id', equals(ref.id))
        .having((c) => c.state, 'state', isNotEmpty)
        .having((c) => c.uri, 'uri', isA<Uri>())
        .having((c) => c.events, 'events', isNotEmpty),
  );

  expect(
    connection.uri.scheme,
    anyOf(equals('http'), equals('https'), equals('ws'), equals('wss')),
  );

  expect(connection.uri.host, isNotEmpty);

  validateEvents(connection);
  validateStatistics(connection);
  validateTimestamps(connection);
}

/// Validate event ordering.
void validateEvents(WebSocketConnection connection) {
  expect(connection.events, isNotEmpty);

  DateTime? previousTimestamp;

  for (final event in connection.events) {
    expect(event.timestamp, isNotNull);

    if (previousTimestamp != null) {
      expect(
        event.timestamp.compareTo(previousTimestamp),
        greaterThanOrEqualTo(0),
      );
    }

    expect(event.event, isNotEmpty);

    const allowedEvents = <String>{
      'WebSocket.Connect',
      'WebSocket.Open',
      'WebSocket.Send',
      'WebSocket.Receive',
      'WebSocket.Ping',
      'WebSocket.Pong',
      'WebSocket.Close',
      'WebSocket.Error',
    };

    expect(allowedEvents, contains(event.event));

    previousTimestamp = event.timestamp;
  }
}

/// Validate counters.
void validateStatistics(WebSocketConnection connection) {
  expect(connection.bytesSent, greaterThanOrEqualTo(0));

  expect(connection.bytesReceived, greaterThanOrEqualTo(0));

  expect(connection.framesSent, greaterThanOrEqualTo(0));

  expect(connection.framesReceived, greaterThanOrEqualTo(0));

  expect(connection.pingCount, greaterThanOrEqualTo(0));

  expect(connection.pongCount, greaterThanOrEqualTo(0));

  if (connection.bytesSent > 0) {
    expect(connection.framesSent, greaterThan(0));
  }

  if (connection.bytesReceived > 0) {
    expect(connection.framesReceived, greaterThan(0));
  }
}

/// Validate timestamps.
void validateTimestamps(WebSocketConnection connection) {
  expect(connection.connectTimestamp, isNotNull);

  expect(connection.lastUpdated, isNotNull);

  expect(
    connection.lastUpdated.compareTo(connection.connectTimestamp),
    greaterThanOrEqualTo(0),
  );

  if (connection.openTimestamp != null) {
    expect(
      connection.openTimestamp!.compareTo(connection.connectTimestamp),
      greaterThanOrEqualTo(0),
    );

    expect(
      connection.lastUpdated.compareTo(connection.openTimestamp!),
      greaterThanOrEqualTo(0),
    );
  }

  if (connection.closeTimestamp != null) {
    expect(
      connection.closeTimestamp!.compareTo(connection.connectTimestamp),
      greaterThanOrEqualTo(0),
    );

    if (connection.openTimestamp != null) {
      expect(
        connection.closeTimestamp!.compareTo(connection.openTimestamp!),
        greaterThanOrEqualTo(0),
      );
    }

    expect(
      connection.lastUpdated.compareTo(connection.closeTimestamp!),
      greaterThanOrEqualTo(0),
    );
  }
}

void main([args = const []]) {
  IsolateTestHarness('get_websocket_profile_lib.dart', args)
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
    vmService = service;

    final isolateId = isolateRef.id!;

    final profile = await service.getWebSocketProfile(isolateId);

    expect(profile, isA<WebSocketProfile>());

    expect(profile.connections, isNotEmpty);

    for (final connection in profile.connections) {
      await validateConnection(isolateId, connection);
    }

    await service.clearWebSocketProfile(isolateId);

    final clearedProfile = await service.getWebSocketProfile(isolateId);

    expect(clearedProfile.connections, isEmpty);
  }).run(testeeMain: testee_lib.main);
}
