// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:convert';

import 'package:dwds/data/devtools_request.dart';
import 'package:dwds/data/extension_request.dart';
import 'package:dwds/src/debugging/execution_context.dart';
import 'package:dwds/src/servers/extension_debugger.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/fakes.dart';

void main() async {
  const debug = false;

  group('ExecutionContext', () {
    setUpAll(() {
      setCurrentLogWriter(debug: debug);
    });

    TestDebuggerConnection? debugger;
    TestDebuggerConnection getDebugger() => debugger!;

    setUp(() async {
      setCurrentLogWriter(debug: debug);
      debugger = TestDebuggerConnection();
    });

    tearDown(() async {
      await debugger?.close();
    });

    test('is created on devtools request', () async {
      final debugger = getDebugger();
      await debugger.createDebuggerExecutionContext(TestContextId.dartDefault);

      // Expect the context ID to be set.
      expect(await debugger.defaultContextId(), TestContextId.dartDefault);
    });

    test('clears context ID', () async {
      final debugger = getDebugger();
      await debugger.createDebuggerExecutionContext(TestContextId.dartDefault);

      debugger.sendContextsClearedEvent();

      // Expect non-dart context.
      expect(await debugger.defaultContextId(), TestContextId.none);
    });

    test('finds dart context ID', () async {
      final debugger = getDebugger();
      await debugger.createDebuggerExecutionContext(TestContextId.none);

      debugger.sendContextCreatedEvent(TestContextId.dartNormal);

      // Expect dart context.
      expect(await debugger.dartContextId(), TestContextId.dartNormal);
    });

    test('does not find dart context ID if not available', () async {
      final debugger = getDebugger();
      await debugger.createDebuggerExecutionContext(TestContextId.none);

      // No context IDs received yet.
      expect(await debugger.defaultContextId(), TestContextId.none);

      debugger.sendContextCreatedEvent(TestContextId.dartLate);

      // Expect no dart context.
      // This mocks injected client still loading.
      expect(await debugger.noContextId(), TestContextId.none);

      // Expect dart context.
      // This mocks injected client loading later for previously
      // received context ID.
      expect(await debugger.dartContextId(), TestContextId.dartLate);
    });

    test('works with stale contexts', () async {
      final debugger = getDebugger();
      await debugger.createDebuggerExecutionContext(TestContextId.none);

      debugger.sendContextCreatedEvent(TestContextId.stale);

      // Expect no dart context.
      expect(await debugger.noContextId(), TestContextId.none);

      debugger.sendContextsClearedEvent();
      debugger.sendContextCreatedEvent(TestContextId.dartNormal);

      // Expect dart context.
      expect(await debugger.dartContextId(), TestContextId.dartNormal);
    });
  });
}

enum TestContextId {
  none,
  dartDefault,
  dartNormal,
  dartLate,
  nonDart,
  stale;

  factory TestContextId.from(int? value) {
    return switch (value) {
      null => none,
      0 => dartDefault,
      1 => dartNormal,
      2 => dartLate,
      3 => nonDart,
      4 => stale,
      _ => throw StateError('$value is not a TestContextId'),
    };
  }

  int? get id {
    return switch (this) {
      none => null,
      dartDefault => 0,
      dartNormal => 1,
      dartLate => 2,
      nonDart => 3,
      stale => 4,
    };
  }
}

class TestExtensionDebugger extends ExtensionDebugger {
  TestExtensionDebugger(FakeSseConnection super.sseConnection);

  @override
  Future<WipResponse> sendCommand(
    String command, {
    Map<String, dynamic>? params,
  }) {
    final id = params?['contextId'] as int?;
    final response = super.sendCommand(command, params: params);

    /// Mock stale contexts that cause the evaluation to throw.
    if (command == 'Runtime.evaluate' &&
        TestContextId.from(id) == TestContextId.stale) {
      throw Exception('Stale execution context');
    }
    return response;
  }
}

class TestDebuggerConnection {
  late final TestExtensionDebugger extensionDebugger;
  late final FakeSseConnection connection;

  int _evaluateRequestId = 0;

  TestDebuggerConnection() {
    connection = FakeSseConnection();
    extensionDebugger = TestExtensionDebugger(connection);
  }

  /// Create a new execution context in the debugger.
  Future<void> createDebuggerExecutionContext(TestContextId contextId) {
    _sendDevToolsRequest(contextId: contextId.id);
    return _executionContext();
  }

  /// Flush the streams and close debugger connection.
  Future<void> close() async {
    unawaited(connection.controllerOutgoing.stream.any((e) => false));
    unawaited(extensionDebugger.devToolsRequestStream.any((e) => false));

    await connection.controllerIncoming.sink.close();
    await connection.controllerOutgoing.sink.close();

    await extensionDebugger.close();
  }

  /// Return the initial context ID from the DevToolsRequest.
  Future<TestContextId> defaultContextId() async {
    // Give the previous events time to propagate.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return TestContextId.from(await extensionDebugger.executionContext!.id);
  }

  /// Mock receiving dart context ID in the execution context.
  ///
  /// Note: dart context is detected by evaluation of
  /// `window.$dartAppInstanceId` in that context returning
  /// a non-null value.
  Future<TestContextId> dartContextId() async {
    // Try getting execution id.
    final executionContextId = extensionDebugger.executionContext!.id;

    // Give it time to send the evaluate request.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Respond to the evaluate request.
    _sendEvaluationResponse({
      'result': {'value': 'dart'},
    });

    return TestContextId.from(await executionContextId);
  }

  /// Mock receiving non-dart context ID in the execution context.
  ///
  /// Note: dart context is detected by evaluation of
  /// `window.$dartAppInstanceId` in that context returning
  /// a null value.
  Future<TestContextId> noContextId() async {
    // Try getting execution id.
    final executionContextId = extensionDebugger.executionContext!.id;

    // Give it time to send the evaluate request.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Respond to the evaluate request.
    _sendEvaluationResponse({
      'result': {'value': null},
    });

    return TestContextId.from(await executionContextId);
  }

  /// Send `Runtime.executionContextsCleared` event to the execution
  /// context in the extension debugger.
  void sendContextsClearedEvent() {
    final extensionEvent = ExtensionEvent(
      method: jsonEncode('Runtime.executionContextsCleared'),
      params: jsonEncode({}),
    );
    connection.controllerIncoming.sink.add(jsonEncode(extensionEvent));
  }

  /// Send `Runtime.executionContextCreated` event to the execution
  /// context in the extension debugger.
  void sendContextCreatedEvent(TestContextId contextId) {
    final extensionEvent = ExtensionEvent(
      method: jsonEncode('Runtime.executionContextCreated'),
      params: jsonEncode({
        'context': {'id': '${contextId.id}'},
      }),
    );
    connection.controllerIncoming.sink.add(jsonEncode(extensionEvent));
  }

  void _sendEvaluationResponse(Map<String, dynamic> response) {
    // Respond to the evaluate request.
    final extensionResponse = ExtensionResponse(
      result: jsonEncode(response),
      id: _evaluateRequestId++,
      success: true,
    );
    connection.controllerIncoming.sink.add(jsonEncode(extensionResponse));
  }

  void _sendDevToolsRequest({int? contextId}) {
    final devToolsRequest = DevToolsRequest(
      contextId: contextId,
      appId: 'app',
      instanceId: '0',
    );
    connection.controllerIncoming.sink.add(jsonEncode(devToolsRequest));
  }

  Future<void> _executionContext() async {
    final executionContext = await _waitForExecutionContext().timeout(
      const Duration(milliseconds: 100),
      onTimeout: () {
        expect(fail, 'Timeout getting execution context');
        return null;
      },
    );
    expect(executionContext, isNotNull);
  }

  Future<ExecutionContext?> _waitForExecutionContext() async {
    while (extensionDebugger.executionContext == null) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return extensionDebugger.executionContext;
  }
}
