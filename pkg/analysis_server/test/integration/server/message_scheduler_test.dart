// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart' as legacy;
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/server/message_scheduler.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MessageSchedulerTest);
  });
}

@reflectiveTest
class MessageSchedulerTest {
  late MessageScheduler messageScheduler;

  DtdMessage get dtdMessage {
    return DtdMessage(
      message: lspRquest,
      performance: OperationPerformanceImpl('<root>'),
      completer: Completer(),
    );
  }

  legacy.Request get legacyRequest {
    var params = AnalysisSetAnalysisRootsParams(['a', 'b', 'c'], ['d', 'e']);
    return legacy.Request(
      '1',
      ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
      params.toJson(clientUriConverter: null),
    );
  }

  lsp.RequestMessage get lspRquest {
    var params = {'processId': 'invalid'};
    return lsp.RequestMessage(
      id: lsp.Either2<int, String>.t1(1),
      method: lsp.Method.initialize,
      params: params,
      jsonrpc: lsp.jsonRpcVersion,
    );
  }

  void setUp() {
    messageScheduler = MessageScheduler();
  }

  void test_addMultipleToQueue() {
    messageScheduler.add(LegacyMessage(request: legacyRequest));
    messageScheduler.add(LspMessage(message: lspRquest));
    messageScheduler.add(dtdMessage);
    _assertQueueContents(r'''
incomingMessages
  LegacyMessage
    method: analysis.setAnalysisRoots
  LspMessage
    method: initialize
  DtdMessage
    method: initialize
''');
  }

  void test_addSingleToQueue() {
    messageScheduler.add(LspMessage(message: lspRquest));
    _assertQueueContents(r'''
incomingMessages
  LspMessage
    method: initialize
''');
  }

  void _assertQueueContents(String expected) {
    var actual = _getQueueContents(messageScheduler.incomingMessages);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
    }
    expect(actual, expected);
  }

  String _getQueueContents(ListQueue<MessageObject> queue) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '  ');
    sink.writeln('incomingMessages');
    while (queue.isNotEmpty) {
      var message = queue.removeFirst();
      switch (message) {
        case DtdMessage():
          sink.writelnWithIndent('DtdMessage');
          sink.withIndent(() {
            sink.writelnWithIndent(
              'method: ${message.message.method.toString()}',
            );
          });
        case LegacyMessage():
          sink.writelnWithIndent('LegacyMessage');
          sink.withIndent(() {
            sink.writelnWithIndent(
              'method: ${message.request.method.toString()}',
            );
          });
        case LspMessage():
          sink.writelnWithIndent('LspMessage');
          var msg = message.message;
          if (msg case lsp.RequestMessage()) {
            sink.withIndent(() {
              sink.writelnWithIndent('method: ${msg.method.toString()}');
            });
          }
      }
    }
    return buffer.toString();
  }
}
