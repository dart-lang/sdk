// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/api/general.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetContentTaskTest);
  });
}

@reflectiveTest
class GetContentTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs = GetContentTask.buildInputs(target);
    expect(inputs, isEmpty);
  }

  test_constructor() {
    AnalysisContext context = new _MockContext();
    AnalysisTarget target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = new _MockContext();
    AnalysisTarget target = new TestSource();
    GetContentTask task = GetContentTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_descriptor() {
    AnalysisContext context = new _MockContext();
    AnalysisTarget target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    expect(task.descriptor, GetContentTask.DESCRIPTOR);
  }

  test_perform() {
    _MockContext context = new _MockContext();
    Source target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    context.getContentsResponse[target] =
        () => new TimestampedData<String>(42, 'foo');
    task.perform();
    expect(task.caughtException, isNull);
    expect(task.outputs, hasLength(2));
    expect(task.outputs[CONTENT], 'foo');
    expect(task.outputs[MODIFICATION_TIME], 42);
  }

  void test_perform_exception() {
    _MockContext context = new _MockContext();
    Source target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    context.getContentsResponse[target] = () => throw 'My exception!';
    task.perform();
    expect(task.caughtException, isNull);
    expect(task.outputs, hasLength(2));
    expect(task.outputs[CONTENT], '');
    expect(task.outputs[MODIFICATION_TIME], -1);
  }
}

class _MockContext implements AnalysisContext {
  Map<Source, TimestampedData<String> Function()> getContentsResponse =
      <Source, TimestampedData<String> Function()>{};

  String get name => 'mock';

  @override
  TimestampedData<String> getContents(Source source) {
    TimestampedData<String> Function() response = getContentsResponse[source];
    if (response == null) {
      fail('Unexpected invocation of getContents');
    }
    return response();
  }

  @override
  noSuchMethod(Invocation invocation) {
    fail('Unexpected invocation of ${invocation.memberName}');
  }
}
