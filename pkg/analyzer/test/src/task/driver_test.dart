// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.driver_test;

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisContextImpl, AnalysisTask;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../context/abstract_context.dart';
import 'test_support.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisDriverTest);
  runReflectiveTests(WorkOrderTest);
  runReflectiveTests(WorkItemTest);
}

@reflectiveTest
class AnalysisDriverTest extends AbstractContextTest {
  AnalysisContextImpl createAnalysisContext() {
    return new _TestContext();
  }

  test_computeResult() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target, descriptor: descriptor);
    taskManager.addTaskDescriptor(descriptor);

    analysisDriver.computeResult(target, result);
    expect(context.getCacheEntry(target).getValue(result), 1);
  }

  test_create() {
    expect(analysisDriver, isNotNull);
    expect(analysisDriver.context, context);
    expect(analysisDriver.currentWorkOrder, isNull);
    expect(analysisDriver.taskManager, taskManager);
  }

  test_createNextWorkOrder_complete() {
    AnalysisTarget priorityTarget = new TestSource();
    AnalysisTarget normalTarget = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    taskManager.addGeneralResult(result);
    taskManager.addTaskDescriptor(descriptor);
    context.priorityTargets.add(priorityTarget);
    context.getCacheEntry(priorityTarget).setValue(
        result, '', TargetedResult.EMPTY_LIST);
    context.explicitTargets.add(normalTarget);
    context.getCacheEntry(priorityTarget).setValue(
        result, '', TargetedResult.EMPTY_LIST);

    expect(analysisDriver.createNextWorkOrder(), isNull);
  }

  test_createNextWorkOrder_normalTarget() {
    AnalysisTarget priorityTarget = new TestSource();
    AnalysisTarget normalTarget = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    taskManager.addGeneralResult(result);
    taskManager.addTaskDescriptor(descriptor);
    context.priorityTargets.add(priorityTarget);
    context.getCacheEntry(priorityTarget).setValue(
        result, '', TargetedResult.EMPTY_LIST);
    context.explicitTargets.add(normalTarget);
    context.getCacheEntry(normalTarget).setState(result, CacheState.INVALID);

    WorkOrder workOrder = analysisDriver.createNextWorkOrder();
    expect(workOrder, isNotNull);
    expect(workOrder.moveNext(), true);
    expect(workOrder.currentItem.target, normalTarget);
  }

  test_createNextWorkOrder_noTargets() {
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    taskManager.addGeneralResult(result);
    taskManager.addTaskDescriptor(descriptor);

    expect(analysisDriver.createNextWorkOrder(), isNull);
  }

  test_createNextWorkOrder_priorityTarget() {
    AnalysisTarget priorityTarget = new TestSource();
    AnalysisTarget normalTarget = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    taskManager.addGeneralResult(result);
    taskManager.addTaskDescriptor(descriptor);
    context.priorityTargets.add(priorityTarget);
    context.getCacheEntry(priorityTarget).setState(result, CacheState.INVALID);
    context.explicitTargets.add(normalTarget);
    context.getCacheEntry(normalTarget).setState(result, CacheState.INVALID);

    WorkOrder workOrder = analysisDriver.createNextWorkOrder();
    expect(workOrder, isNotNull);
    expect(workOrder.moveNext(), true);
    expect(workOrder.currentItem.target, priorityTarget);
  }

  test_createWorkOrderForResult_error() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    CaughtException exception = new CaughtException(null, null);
    context.getCacheEntry(target).setErrorState(
        exception, <ResultDescriptor>[result]);

    expect(analysisDriver.createWorkOrderForResult(target, result), isNull);
  }

  test_createWorkOrderForResult_inProcess() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    context.getCacheEntry(target).setState(result, CacheState.IN_PROCESS);

    expect(analysisDriver.createWorkOrderForResult(target, result), isNull);
  }

  test_createWorkOrderForResult_invalid() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    taskManager.addTaskDescriptor(descriptor);
    context.getCacheEntry(target).setState(result, CacheState.INVALID);

    WorkOrder workOrder =
        analysisDriver.createWorkOrderForResult(target, result);
    expect(workOrder, isNotNull);
  }

  test_createWorkOrderForResult_valid() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    context.getCacheEntry(target).setValue(
        result, '', TargetedResult.EMPTY_LIST);

    expect(analysisDriver.createWorkOrderForResult(target, result), isNull);
  }

  test_createWorkOrderForTarget_complete_generalTarget_generalResult() {
    _createWorkOrderForTarget(true, false, false);
  }

  test_createWorkOrderForTarget_complete_generalTarget_priorityResult() {
    _createWorkOrderForTarget(true, false, true);
  }

  test_createWorkOrderForTarget_complete_priorityTarget_generalResult() {
    _createWorkOrderForTarget(true, true, false);
  }

  test_createWorkOrderForTarget_complete_priorityTarget_priorityResult() {
    _createWorkOrderForTarget(true, true, true);
  }

  test_createWorkOrderForTarget_incomplete_generalTarget_generalResult() {
    _createWorkOrderForTarget(false, false, false);
  }

  test_createWorkOrderForTarget_incomplete_generalTarget_priorityResult() {
    _createWorkOrderForTarget(false, false, true);
  }

  test_createWorkOrderForTarget_incomplete_priorityTarget_generalResult() {
    _createWorkOrderForTarget(false, true, false);
  }

  test_createWorkOrderForTarget_incomplete_priorityTarget_priorityResult() {
    _createWorkOrderForTarget(false, true, true);
  }

  test_performAnalysisTask() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target, descriptor: descriptor);
    taskManager.addTaskDescriptor(descriptor);
    taskManager.addGeneralResult(result);
    context.priorityTargets.add(target);

    expect(analysisDriver.performAnalysisTask(), true);
    expect(analysisDriver.performAnalysisTask(), true);
    expect(analysisDriver.performAnalysisTask(), false);
  }

  test_performAnalysisTask_infiniteLoop() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor resultA = new ResultDescriptor('resultA', -1);
    ResultDescriptor resultB = new ResultDescriptor('resultB', -2);
    // configure tasks
    TestAnalysisTask task1;
    TestAnalysisTask task2;
    TaskDescriptor descriptor1 = new TaskDescriptor('task1',
        (context, target) => task1, (target) => {
      'inputB': new SimpleTaskInput<int>(target, resultB)
    }, [resultA]);
    TaskDescriptor descriptor2 = new TaskDescriptor('task2',
        (context, target) => task2, (target) => {
      'inputA': new SimpleTaskInput<int>(target, resultA)
    }, [resultB]);
    task1 = new TestAnalysisTask(context, target, descriptor: descriptor1);
    task2 = new TestAnalysisTask(context, target, descriptor: descriptor2);
    taskManager.addTaskDescriptor(descriptor1);
    taskManager.addTaskDescriptor(descriptor2);
    context.explicitTargets.add(target);
    taskManager.addGeneralResult(resultB);
    // prepare work order
    expect(analysisDriver.performAnalysisTask(), true);
    expect(analysisDriver.performAnalysisTask(), true);
    CaughtException exception = context.getCacheEntry(target).exception;
    expect(exception, isNotNull);
    expect(exception.exception, new isInstanceOf<InfiniteTaskLoopException>());
  }

  test_performAnalysisTask_inputsFirst() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor resultA = new ResultDescriptor('resultA', -1);
    ResultDescriptor resultB = new ResultDescriptor('resultB', -2);
    // configure tasks
    TestAnalysisTask task1;
    TestAnalysisTask task2;
    TaskDescriptor descriptor1 = new TaskDescriptor(
        'task1', (context, target) => task1, (target) => {}, [resultA]);
    TaskDescriptor descriptor2 = new TaskDescriptor('task2',
        (context, target) => task2, (target) => {
      'inputA': new SimpleTaskInput<int>(target, resultA)
    }, [resultB]);
    task1 = new TestAnalysisTask(context, target,
        descriptor: descriptor1, results: [resultA], value: 10);
    task2 = new TestAnalysisTask(context, target,
        descriptor: descriptor2, value: 20);
    taskManager.addTaskDescriptor(descriptor1);
    taskManager.addTaskDescriptor(descriptor2);
    context.explicitTargets.add(target);
    taskManager.addGeneralResult(resultB);
    // prepare work order
    expect(analysisDriver.performAnalysisTask(), true);
    expect(context.getCacheEntry(target).getValue(resultA), -1);
    expect(context.getCacheEntry(target).getValue(resultB), -2);
    // compute resultA
    expect(analysisDriver.performAnalysisTask(), true);
    expect(context.getCacheEntry(target).getValue(resultA), 10);
    expect(context.getCacheEntry(target).getValue(resultB), -2);
    // compute resultB
    expect(analysisDriver.performAnalysisTask(), true);
    expect(context.getCacheEntry(target).getValue(resultA), 10);
    expect(context.getCacheEntry(target).getValue(resultB), 20);
    // done
    expect(analysisDriver.performAnalysisTask(), false);
  }

  test_performWorkItem_exceptionInTask() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    CaughtException exception =
        new CaughtException(new AnalysisException(), null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target,
        descriptor: descriptor, exception: exception);
    WorkItem item = new WorkItem(context, target, descriptor);

    analysisDriver.performWorkItem(item);
    CacheEntry targetEntry = context.getCacheEntry(item.target);
    expect(targetEntry.exception, exception);
    expect(targetEntry.getState(result), CacheState.ERROR);
  }

  test_performWorkItem_noException() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target, descriptor: descriptor);
    WorkItem item = new WorkItem(context, target, descriptor);

    analysisDriver.performWorkItem(item);
    CacheEntry targetEntry = context.getCacheEntry(item.target);
    expect(targetEntry.exception, isNull);
    expect(targetEntry.getState(result), CacheState.VALID);
  }

  test_performWorkItem_preExistingException() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    CaughtException exception =
        new CaughtException(new AnalysisException(), null);
    WorkItem item = new WorkItem(context, target, descriptor);
    item.exception = exception;

    analysisDriver.performWorkItem(item);
    CacheEntry targetEntry = context.getCacheEntry(item.target);
    expect(targetEntry.exception, exception);
    expect(targetEntry.getState(result), CacheState.ERROR);
  }

  test_reset() {
    ResultDescriptor inputResult = new ResultDescriptor('input', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {'one': inputResult.of(target)},
        [new ResultDescriptor('output', null)]);
    analysisDriver.currentWorkOrder =
        new WorkOrder(taskManager, new WorkItem(null, null, descriptor));

    analysisDriver.reset();
    expect(analysisDriver.currentWorkOrder, isNull);
  }

  /**
   * [complete] is `true` if the value of the result has already been computed.
   * [priorityTarget] is `true` if the target is in the list of priority
   * targets.
   * [priorityResult] is `true` if the result should only be computed for
   * priority targets.
   */
  _createWorkOrderForTarget(
      bool complete, bool priorityTarget, bool priorityResult) {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    if (priorityResult) {
      taskManager.addPriorityResult(result);
    } else {
      taskManager.addGeneralResult(result);
    }
    taskManager.addTaskDescriptor(descriptor);
    if (priorityTarget) {
      context.priorityTargets.add(target);
    } else {
      context.explicitTargets.add(target);
    }
    if (complete) {
      context.getCacheEntry(target).setValue(
          result, '', TargetedResult.EMPTY_LIST);
    } else {
      context.getCacheEntry(target).setState(result, CacheState.INVALID);
    }

    WorkOrder workOrder =
        analysisDriver.createWorkOrderForTarget(target, priorityTarget);
    if (complete) {
      expect(workOrder, isNull);
    } else if (priorityResult) {
      expect(workOrder, priorityTarget ? isNotNull : isNull);
    } else {
      expect(workOrder, isNotNull);
    }
  }
}

@reflectiveTest
class WorkItemTest extends EngineTestCase {
  test_buildTask_complete() {
    AnalysisContext context = new AnalysisContextImpl();
    AnalysisTarget target = new TestSource();
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [new ResultDescriptor('output', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    AnalysisTask task = item.buildTask();
    expect(task, isNotNull);
  }

  test_buildTask_incomplete() {
    AnalysisContext context = new AnalysisContextImpl();
    AnalysisTarget target = new TestSource();
    ResultDescriptor inputResult = new ResultDescriptor('input', null);
    List<ResultDescriptor> outputResults =
        <ResultDescriptor>[new ResultDescriptor('output', null)];
    TaskDescriptor descriptor = new TaskDescriptor('task', (context, target) =>
            new TestAnalysisTask(context, target, results: outputResults),
        (target) => {'one': inputResult.of(target)}, outputResults);
    WorkItem item = new WorkItem(context, target, descriptor);
    expect(() => item.buildTask(), throwsStateError);
  }

  test_create() {
    AnalysisContext context = new AnalysisContextImpl();
    AnalysisTarget target = new TestSource();
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', null, (target) => {}, [new ResultDescriptor('result', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    expect(item, isNotNull);
    expect(item.context, context);
    expect(item.descriptor, descriptor);
    expect(item.target, target);
  }

  test_gatherInputs_complete() {
    TaskManager manager = new TaskManager();
    AnalysisContext context = new AnalysisContextImpl();
    AnalysisTarget target = new TestSource();
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [new ResultDescriptor('output', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    WorkItem result = item.gatherInputs(manager);
    expect(result, isNull);
    expect(item.exception, isNull);
  }

  test_gatherInputs_incomplete() {
    TaskManager manager = new TaskManager();
    AnalysisContextImpl context = new AnalysisContextImpl();
    AnalysisTarget target = new TestSource();
    ResultDescriptor resultA = new ResultDescriptor('resultA', null);
    ResultDescriptor resultB = new ResultDescriptor('resultB', null);
    // prepare tasks
    TaskDescriptor task1 = new TaskDescriptor('task', (context, target) =>
            new TestAnalysisTask(context, target, results: [resultA]),
        (target) => {}, [resultA]);
    TaskDescriptor task2 = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {'one': resultA.of(target)}, [resultB]);
    manager.addTaskDescriptor(task1);
    manager.addTaskDescriptor(task2);
    // gather inputs
    WorkItem item = new WorkItem(context, target, task2);
    WorkItem inputItem = item.gatherInputs(manager);
    expect(inputItem, isNotNull);
  }

  test_gatherInputs_invalid() {
    TaskManager manager = new TaskManager();
    AnalysisContext context = new AnalysisContextImpl();
    AnalysisTarget target = new TestSource();
    ResultDescriptor inputResult = new ResultDescriptor('input', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {'one': inputResult.of(target)},
        [new ResultDescriptor('output', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    WorkItem result = item.gatherInputs(manager);
    expect(result, isNull);
    expect(item.exception, isNotNull);
  }
}

@reflectiveTest
class WorkOrderTest extends EngineTestCase {
  test_create() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', null, (_) => {}, [new ResultDescriptor('result', null)]);
    WorkOrder order =
        new WorkOrder(manager, new WorkItem(null, null, descriptor));
    expect(order, isNotNull);
    expect(order.currentItem, isNull);
    expect(order.pendingItems, hasLength(1));
    expect(order.taskManager, manager);
  }

  test_moveNext() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', null, (_) => {}, [new ResultDescriptor('result', null)]);
    WorkItem workItem = new WorkItem(null, null, descriptor);
    WorkOrder order = new WorkOrder(manager, workItem);
    // "item" has no child items
    expect(order.moveNext(), isTrue);
    expect(order.current, workItem);
    // done
    expect(order.moveNext(), isFalse);
    expect(order.current, isNull);
  }
}

/**
 * An [AnalysisContextImpl] which allows to set explicit and implicit targets
 * directly.
 */
class _TestContext extends AnalysisContextImpl {
  @override
  List<AnalysisTarget> explicitTargets = <AnalysisTarget>[];

  @override
  List<AnalysisTarget> priorityTargets = <AnalysisTarget>[];
}
