// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/services/dart_tooling_daemon/dtd_services.dart';
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DtdServicesTest);
  });
}

@reflectiveTest
class DtdServicesTest {
  late TestAnalysisServer server;
  late DtdServices dtdServices;
  final testUri = Uri.parse('ws://localhost:1234');

  void setUp() {
    server = TestAnalysisServer();
    dtdServices = DtdServices.forTesting(server, testUri);
  }

  Future<void>
  test_processMessage_completesOnError_inconsistentAnalysis() async {
    server.exceptionToThrow = InconsistentAnalysisException();

    var (:response, :scheduler) = _processTestMessage();

    var expectedException = isA<RpcException>().having(
      (e) => e.code,
      'code',
      ErrorCodes.ContentModified.toJson(),
    );
    await expectLater(response, throwsA(expectedException));
    expect(scheduler.isCompleted, isTrue);
  }

  Future<void> test_processMessage_completesOnError_lspError() async {
    server.resultToReturn = ErrorOr<Object?>.error(
      ResponseError(
        code: ServerErrorCodes.invalidFilePath,
        message: 'File does not exist',
      ),
    );

    var (:response, :scheduler) = _processTestMessage();

    var expectedException = isA<RpcException>()
        .having(
          (e) => e.code,
          'code',
          ServerErrorCodes.invalidFilePath.toJson(),
        )
        .having((e) => e.message, 'message', 'File does not exist');
    await expectLater(response, throwsA(expectedException));
    expect(scheduler.isCompleted, isTrue);
  }

  Future<void> test_processMessage_completesOnError_unhandledException() async {
    server.exceptionToThrow = StateError('Simulated crash in handler');

    var (:response, :scheduler) = _processTestMessage();

    var expectedException = isA<RpcException>()
        .having((e) => e.code, 'code', ServerErrorCodes.unhandledError.toJson())
        .having(
          (e) => e.message,
          'message',
          'An error occurred while handling textDocument/hover request',
        );
    await expectLater(response, throwsA(expectedException));
    expect(scheduler.isCompleted, isTrue);
  }

  Future<void> test_processMessage_completesOnSuccess() async {
    server.resultToReturn = success(<String, Object?>{'title': 'Test'});

    var (:response, :scheduler) = _processTestMessage();

    var result = await response;
    expect(result['result'], equals(<String, Object?>{'title': 'Test'}));
    expect(scheduler.isCompleted, isTrue);
  }

  ({Future<Map<String, Object?>> response, Completer<void> scheduler})
  _processTestMessage() {
    var message = RequestMessage(
      id: const Either2.t1(1),
      jsonrpc: jsonRpcVersion,
      method: Method.textDocument_hover,
    );
    var performance = OperationPerformanceImpl('<root>');
    var responseCompleter = Completer<Map<String, Object?>>();
    var schedulerCompleter = Completer<void>();

    dtdServices.processMessage(
      message,
      performance,
      responseCompleter,
      schedulerCompleter,
    );

    return (response: responseCompleter.future, scheduler: schedulerCompleter);
  }
}

class TestAnalysisServer implements AnalysisServer {
  Object? exceptionToThrow;

  @override
  final InstrumentationService instrumentationService =
      NoopInstrumentationService();

  ErrorOr<Object?>? resultToReturn;

  @override
  final SessionLogger sessionLogger = SessionLogger();

  @override
  FutureOr<ErrorOr<Object?>> immediatelyHandleLspMessage(
    IncomingMessage message,
    MessageInfo messageInfo, {
    CancellationToken? cancellationToken,
  }) {
    if (exceptionToThrow case var exception?) {
      throw exception;
    }
    return resultToReturn ?? success(null);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
