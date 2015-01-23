// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation.queue;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';
import '../mocks.dart';
import 'package:analyzer/src/generated/source.dart';

main() {
  groupSep = ' | ';

  group('ServerOperationQueue', () {
    ServerOperationQueue queue;

    setUp(() {
      queue = new ServerOperationQueue();
    });

    test('clear', () {
      var operationA = mockOperation(ServerOperationPriority.ANALYSIS);
      var operationB = mockOperation(ServerOperationPriority.ANALYSIS_CONTINUE);
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
        var operation = mockOperation(ServerOperationPriority.ANALYSIS);
        queue.add(operation);
        expect(queue.isEmpty, isFalse);
      });
    });

    group('take', () {
      test('empty', () {
        expect(queue.take(), isNull);
      });

      test('use operation priorities', () {
        var operationA = mockOperation(ServerOperationPriority.ANALYSIS);
        var operationB =
            mockOperation(ServerOperationPriority.ANALYSIS_CONTINUE);
        var operationC =
            mockOperation(ServerOperationPriority.PRIORITY_ANALYSIS);
        queue.add(operationA);
        queue.add(operationB);
        queue.add(operationC);
        expect(queue.take(), operationC);
        expect(queue.take(), operationB);
        expect(queue.take(), operationA);
        expect(queue.take(), isNull);
      });

      test('continue analysis first', () {
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
        var prioritySource = new MockSource();
        var analysisContextA = new AnalysisContextMock();
        var analysisContextB = new AnalysisContextMock();
        analysisContextB.prioritySources = [prioritySource];
        var operationA = new PerformAnalysisOperation(analysisContextA, false);
        var operationB = new PerformAnalysisOperation(analysisContextB, false);
        queue.add(operationA);
        queue.add(operationB);
        expect(queue.take(), operationB);
        expect(queue.take(), operationA);
        expect(queue.take(), isNull);
      });

      test('reschedule', () {
        var prioritySource = new MockSource();
        var analysisContextA = new AnalysisContextMock();
        var analysisContextB = new AnalysisContextMock();
        var operationA = new PerformAnalysisOperation(analysisContextA, false);
        var operationB = new PerformAnalysisOperation(analysisContextB, false);
        queue.add(operationA);
        queue.add(operationB);
        // update priority sources and reschedule
        analysisContextB.prioritySources = [prioritySource];
        queue.reschedule();
        // verify order
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


class AnalysisContextMock extends TypedMock implements InternalAnalysisContext {
  List<Source> prioritySources = <Source>[];

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AnalysisServerMock extends TypedMock implements AnalysisServer {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ServerContextManagerMock extends TypedMock implements ServerContextManager
    {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ServerOperationMock extends TypedMock implements ServerOperation {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
