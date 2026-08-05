// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--timeline_streams=Dart

import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

/// Generates WebSocket timeline activity by establishing a connection,
/// exchanging a text message, and closing the connection.
Future<void> testeeMain(List<String> args) async {
  HttpClient.enableTimelineLogging = true;

  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );

  server.transform(WebSocketTransformer()).listen((socket) {
    socket.listen((message) {
      socket.add(message);
    });
  });

  final client = await WebSocket.connect(
    'ws://${server.address.host}:${server.port}',
  );

  client.add('hello');

  await client.first;

  await client.close(
    WebSocketStatus.normalClosure,
    'bye',
  );

  await server.close();
}

class ContainsTimelineEvent extends CustomMatcher {
  final String name;
  final Map<String, dynamic>? expectedArgs;

  ContainsTimelineEvent(
    this.name, {
    this.expectedArgs,
  }) : super(
          'timeline event "$name"',
          'timeline event',
          anything,
        );

  @override
  Object? featureValueOf(dynamic actual) {
    if (actual is! List<TimelineEvent>) {
      return null;
    }

    for (final timelineEvent in actual) {
      final event = timelineEvent.json!;

      if (event['name'] != name) {
        continue;
      }

      if (expectedArgs == null) {
        return event;
      }

      final actualArgs = event['args'];
      if (actualArgs is! Map) {
        throw StateError(
          'Expected timeline event args to be a Map, '
          'got ${actualArgs.runtimeType}',
        );
      }

      final matches = expectedArgs!.entries.every(
        (entry) => actualArgs[entry.key] == entry.value,
      );

      if (matches) {
        return event;
      }
    }

    return null;
  }
}

/// Returns a matcher that verifies the timeline contains an event
/// with the given name and optional argument subset.
Matcher containsTimelineEvent(
  String name, {
  Map<String, dynamic>? expectedArgs,
}) {
  return ContainsTimelineEvent(
    name,
    expectedArgs: expectedArgs,
  );
}

/// Binary frame events are not verified separately because they follow the
/// same instrumentation path as text frames.
///
/// Ping and Pong events are not verified here because they are emitted by
/// timer-driven keep alive logic, making their occurrence timing-dependent.
final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final timeline = await service.getVMTimeline();
    final traceEvents = timeline.traceEvents!;

    expect(traceEvents, isNotEmpty);

    expect(
      traceEvents,
      containsTimelineEvent(
        'WebSocket.Connect',
      ),
    );

    expect(
      traceEvents,
      containsTimelineEvent(
        'WebSocket.Send',
        expectedArgs: {
          'direction': 'out',
          'opcode': 'text',
        },
      ),
    );

    expect(
      traceEvents,
      containsTimelineEvent(
        'WebSocket.Receive',
        expectedArgs: {
          'direction': 'in',
          'opcode': 'text',
        },
      ),
    );

    expect(
      traceEvents,
      containsTimelineEvent(
        'WebSocket.Close',
        expectedArgs: {
          'direction': 'out',
          'closeCode': WebSocketStatus.normalClosure,
          'reason': 'bye',
        },
      ),
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'verify_websocket_timeline_test.dart',
      testeeMain: testeeMain,
      extraArgs: ['--complete-timeline'],
    );
