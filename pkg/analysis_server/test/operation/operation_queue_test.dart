// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation.queue;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerOperationQueueTest);
  });
}

/**
 *  Return a [ServerOperation] mock with the given priority.
 */
ServerOperation mockOperation(ServerOperationPriority priority) {
  ServerOperation operation = new _ServerOperationMock();
  when(operation.priority).thenReturn(priority);
  return operation;
}

class AnalysisContextMock extends TypedMock implements InternalAnalysisContext {
  List<Source> prioritySources = <Source>[];
}

class AnalysisServerMock extends TypedMock implements AnalysisServer {
  @override
  final ResourceProvider resourceProvider;

  @override
  final SearchEngine searchEngine;

  AnalysisServerMock({this.resourceProvider, this.searchEngine});
}

class ServerContextManagerMock extends TypedMock implements ContextManager {}

@reflectiveTest
class ServerOperationQueueTest {
  ServerOperationQueue queue = new ServerOperationQueue();

  void test_add_withMerge() {
    var opA = new _MergeableOperationMock();
    var opB = new _MergeableOperationMock();
    var opC = new _MergeableOperationMock();
    when(opA.merge(opC)).thenReturn(true);
    when(opA.merge(anyObject)).thenReturn(false);
    when(opB.merge(anyObject)).thenReturn(false);
    when(opC.merge(anyObject)).thenReturn(false);
    queue.add(opA);
    queue.add(opB);
    queue.add(opC);
    expect(queue.take(), same(opA));
    expect(queue.take(), same(opB));
    // no opC, it was merged into opA
    expect(queue.isEmpty, isTrue);
  }

  void test_clear() {
    var operationA = mockOperation(ServerOperationPriority.ANALYSIS);
    var operationB = mockOperation(ServerOperationPriority.ANALYSIS_CONTINUE);
    queue.add(operationA);
    queue.add(operationB);
    // there are some operations
    expect(queue.isEmpty, false);
    // clear - no operations
    queue.clear();
    expect(queue.isEmpty, true);
  }

  void test_contextRemoved() {
    var contextA = new AnalysisContextMock();
    var contextB = new AnalysisContextMock();
    var opA1 = new _ServerOperationMock(contextA);
    var opA2 = new _ServerOperationMock(contextA);
    var opB1 = new _ServerOperationMock(contextB);
    var opB2 = new _ServerOperationMock(contextB);
    when(opA1.priority)
        .thenReturn(ServerOperationPriority.ANALYSIS_NOTIFICATION);
    when(opA2.priority)
        .thenReturn(ServerOperationPriority.ANALYSIS_NOTIFICATION);
    when(opB1.priority)
        .thenReturn(ServerOperationPriority.ANALYSIS_NOTIFICATION);
    when(opB2.priority)
        .thenReturn(ServerOperationPriority.ANALYSIS_NOTIFICATION);
    queue.add(opA1);
    queue.add(opB1);
    queue.add(opA2);
    queue.add(opB2);
    queue.contextRemoved(contextA);
    expect(queue.take(), same(opB1));
    expect(queue.take(), same(opB2));
  }

  void test_isEmpty_false() {
    var operation = mockOperation(ServerOperationPriority.ANALYSIS);
    queue.add(operation);
    expect(queue.isEmpty, isFalse);
  }

  void test_isEmpty_true() {
    expect(queue.isEmpty, isTrue);
  }

  void test_peek() {
    var operationA = mockOperation(ServerOperationPriority.ANALYSIS);
    var operationB = mockOperation(ServerOperationPriority.ANALYSIS);
    queue.add(operationA);
    queue.add(operationB);
    expect(queue.peek(), operationA);
    expect(queue.peek(), operationA);
    expect(queue.peek(), operationA);
  }

  void test_peek_empty() {
    expect(queue.peek(), isNull);
  }

  void test_reschedule() {
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
  }

  void test_sourceAboutToChange() {
    Source sourceA = new _SourceMock();
    Source sourceB = new _SourceMock();
    var opA1 = new _SourceSensitiveOperationMock(sourceA);
    var opA2 = new _SourceSensitiveOperationMock(sourceA);
    var opB1 = new _SourceSensitiveOperationMock(sourceB);
    var opB2 = new _SourceSensitiveOperationMock(sourceB);
    queue.add(opA1);
    queue.add(opB1);
    queue.add(opA2);
    queue.add(opB2);
    queue.sourceAboutToChange(sourceA);
    expect(queue.take(), same(opB1));
    expect(queue.take(), same(opB2));
  }

  void test_take_continueAnalysisFirst() {
    var analysisContext = new AnalysisContextMock();
    var operationA = new PerformAnalysisOperation(analysisContext, false);
    var operationB = new PerformAnalysisOperation(analysisContext, true);
    queue.add(operationA);
    queue.add(operationB);
    expect(queue.take(), operationB);
    expect(queue.take(), operationA);
    expect(queue.take(), isNull);
  }

  void test_take_empty() {
    expect(queue.take(), isNull);
  }

  void test_take_priorityContextFirst() {
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
  }

  void test_take_useOperationPriorities() {
    var operationA = mockOperation(ServerOperationPriority.ANALYSIS);
    var operationB = mockOperation(ServerOperationPriority.ANALYSIS_CONTINUE);
    var operationC = mockOperation(ServerOperationPriority.PRIORITY_ANALYSIS);
    queue.add(operationA);
    queue.add(operationB);
    queue.add(operationC);
    expect(queue.take(), operationC);
    expect(queue.take(), operationB);
    expect(queue.take(), operationA);
    expect(queue.take(), isNull);
  }

  void test_takeIf() {
    var operationA = mockOperation(ServerOperationPriority.ANALYSIS);
    var operationB = mockOperation(ServerOperationPriority.ANALYSIS);
    queue.add(operationA);
    queue.add(operationB);
    expect(queue.takeIf((_) => false), isNull);
    expect(queue.takeIf((operation) => operation == operationB), operationB);
    expect(queue.takeIf((operation) => operation == operationB), isNull);
    expect(queue.takeIf((operation) => operation == operationA), operationA);
    expect(queue.isEmpty, isTrue);
  }
}

class _MergeableOperationMock extends TypedMock implements MergeableOperation {
  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_NOTIFICATION;
  }
}

class _ServerOperationMock extends TypedMock implements ServerOperation {
  final AnalysisContext context;

  _ServerOperationMock([this.context]);
}

class _SourceMock extends TypedMock implements Source {}

class _SourceSensitiveOperationMock extends TypedMock
    implements SourceSensitiveOperation {
  final Source source;

  _SourceSensitiveOperationMock(this.source);

  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_NOTIFICATION;
  }

  @override
  bool shouldBeDiscardedOnSourceChange(Source source) {
    return source == this.source;
  }
}
