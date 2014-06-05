// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation.queue;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';

  group('ServerOperationQueue', () {
    AnalysisServer server;
    ServerOperationQueue queue;

    setUp(() {
      server = new AnalysisServerMock();
      queue = new ServerOperationQueue(server);
    });

    test('clear', () {
      var operationA = mockOperation(ServerOperationPriority.SEARCH);
      var operationB = mockOperation(ServerOperationPriority.REFACTORING);
      queue.add(operationA);
      queue.add(operationB);
      // there are some operations
      expect(queue.isEmpty, false);
      // clear - no operations
      queue.clear();
      expect(queue.isEmpty, true);
    });

    group('isEmpty', () {
      test('true', () {
        expect(queue.isEmpty, isTrue);
      });

      test('false', () {
        var operation = mockOperation(ServerOperationPriority.SEARCH);
        queue.add(operation);
        expect(queue.isEmpty, isFalse);
      });
    });

    group('take', () {
      test('empty', () {
        expect(queue.take(), isNull);
      });

      test('use operation priorities', () {
        when(server.isPriorityContext(anyObject)).thenReturn(false);
        var analysisContext = new AnalysisContextMock();
        var operationA = mockOperation(ServerOperationPriority.SEARCH);
        var operationB = mockOperation(ServerOperationPriority.REFACTORING);
        var operationC = new PerformAnalysisOperation(analysisContext, false);
        queue.add(operationA);
        queue.add(operationB);
        queue.add(operationC);
        expect(queue.take(), operationC);
        expect(queue.take(), operationA);
        expect(queue.take(), operationB);
        expect(queue.take(), isNull);
      });

      test('continue analysis first', () {
        when(server.isPriorityContext(anyObject)).thenReturn(false);
        var analysisContext = new AnalysisContextMock();
        var operationA = new PerformAnalysisOperation(analysisContext, false);
        var operationB = new PerformAnalysisOperation(analysisContext, true);
        queue.add(operationA);
        queue.add(operationB);
        expect(queue.take(), operationB);
        expect(queue.take(), operationA);
        expect(queue.take(), isNull);
      });

      test('priority context first', () {
        var analysisContextA = new AnalysisContextMock();
        var analysisContextB = new AnalysisContextMock();
        var operationA = new PerformAnalysisOperation(analysisContextA, false);
        var operationB = new PerformAnalysisOperation(analysisContextB, false);
        queue.add(operationA);
        queue.add(operationB);
        when(server.isPriorityContext(analysisContextA)).thenReturn(false);
        when(server.isPriorityContext(analysisContextB)).thenReturn(true);
        expect(queue.take(), operationB);
        expect(queue.take(), operationA);
        expect(queue.take(), isNull);
      });
    });
  });
}


/**
 *  Return a [ServerOperation] mock with the given priority.
 */
ServerOperation mockOperation(ServerOperationPriority priority) {
  ServerOperation operation = new ServerOperationMock();
  when(operation.priority).thenReturn(priority);
  return operation;
}


class AnalysisContextMock extends TypedMock implements AnalysisContext {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ServerOperationMock extends TypedMock implements ServerOperation {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AnalysisServerMock extends TypedMock implements AnalysisServer {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
