// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.manager_test;

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TaskManagerTest);
  });
}

@reflectiveTest
class TaskManagerTest extends EngineTestCase {
  static final ResultDescriptor result1 = new ResultDescriptor('result1', null);
  static final ResultDescriptor result2 = new ResultDescriptor('result2', null);

  test_addGeneralResult() {
    TaskManager manager = new TaskManager();
    manager.addGeneralResult(result1);
    Set<ResultDescriptor> results = manager.generalResults;
    expect(results, unorderedEquals([result1]));
  }

  test_addPriorityResult() {
    TaskManager manager = new TaskManager();
    manager.addPriorityResult(result1);
    Set<ResultDescriptor> results = manager.priorityResults;
    expect(results, unorderedEquals([result1]));
  }

  test_addTaskDescriptor() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor =
        new TaskDescriptor('task', null, null, [result1]);
    manager.addTaskDescriptor(descriptor);
    expect(manager.taskMap.length, 1);
  }

  test_constructor() {
    TaskManager manager = new TaskManager();
    expect(manager, isNotNull);
    expect(manager.generalResults, isEmpty);
    expect(manager.priorityResults, isEmpty);
  }

  test_findTask_defined() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor =
        new TaskDescriptor('task', null, null, [result1]);
    manager.addTaskDescriptor(descriptor);
    AnalysisTarget target = new TestSource();
    expect(manager.findTask(target, result1), descriptor);
  }

  test_findTask_empty() {
    TaskManager manager = new TaskManager();
    AnalysisTarget target = new TestSource();
    expect(() => manager.findTask(target, result1),
        throwsA(new isInstanceOf<AnalysisException>()));
  }

  test_findTask_multiple() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor1 =
        new TaskDescriptor('task1', null, null, [result1]);
    manager.addTaskDescriptor(descriptor1);
    TaskDescriptor descriptor2 =
        new TaskDescriptor('task2', null, null, [result1]);
    manager.addTaskDescriptor(descriptor2);
    TaskDescriptor descriptor3 =
        new TaskDescriptor('task3', null, null, [result2]);
    manager.addTaskDescriptor(descriptor3);

    AnalysisTarget target = new TestSource();
    TaskDescriptor task = manager.findTask(target, result1);
    expect(task == descriptor1 || task == descriptor2, true);
  }

  test_findTask_undefined() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor =
        new TaskDescriptor('task', null, null, [result1]);
    manager.addTaskDescriptor(descriptor);
    AnalysisTarget target = new TestSource();
    expect(() => manager.findTask(target, result2),
        throwsA(new isInstanceOf<AnalysisException>()));
  }

  test_removeGeneralResult_absent() {
    TaskManager manager = new TaskManager();
    manager.addGeneralResult(result1);
    Set<ResultDescriptor> results = manager.generalResults;
    expect(results, unorderedEquals([result1]));
  }

  test_removeGeneralResult_present() {
    TaskManager manager = new TaskManager();
    manager.addGeneralResult(result1);
    manager.addGeneralResult(result2);
    Set<ResultDescriptor> results = manager.generalResults;
    expect(results, unorderedEquals([result1, result2]));
    manager.removeGeneralResult(result1);
    expect(results, unorderedEquals([result2]));
  }

  test_removePriorityResult_absent() {
    TaskManager manager = new TaskManager();
    manager.addPriorityResult(result1);
    manager.removePriorityResult(result2);
    Set<ResultDescriptor> results = manager.priorityResults;
    expect(results, unorderedEquals([result1]));
  }

  test_removePriorityResult_present() {
    TaskManager manager = new TaskManager();
    manager.addPriorityResult(result1);
    manager.addPriorityResult(result2);
    Set<ResultDescriptor> results = manager.priorityResults;
    expect(results, unorderedEquals([result1, result2]));
    manager.removePriorityResult(result1);
    expect(results, unorderedEquals([result2]));
  }
}
