// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests basic functionality of tasks in zones.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

List log = [];

class MySpecification extends TaskSpecification {
  final Function callback;
  final bool isOneShot;
  final int value;

  MySpecification(void this.callback(), this.isOneShot, this.value);

  String get name => "test.specification-name";
}

class MyTask {
  final Zone zone;
  final Function callback;
  final int id;
  int invocationCount = 0;
  bool shouldStop = false;

  MyTask(this.zone, void this.callback(), this.id);
}

void runMyTask(MyTask task, int value) {
  log.add("running "
      "zone: ${Zone.current['name']} "
      "task-id: ${task.id} "
      "invocation-count: ${task.invocationCount} "
      "value: $value");
  task.callback();
  task.invocationCount++;
}

MyTask createMyTask(MySpecification spec, Zone zone) {
  var task = new MyTask(zone, spec.callback, spec.value);
  log.add("creating task: ${spec.value} oneshot?: ${spec.isOneShot}");
  if (spec.isOneShot) {
    Timer.run(() {
      zone.runTask(runMyTask, task, task.id);
    });
  } else {
    new Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
      zone.runTask(runMyTask, task, task.id);
      if (task.shouldStop) {
        timer.cancel();
      }
    });
  }
  return task;
}

MyTask startTask(f, bool oneShot, int value) {
  var spec = new MySpecification(f, oneShot, value);
  return Zone.current.createTask(createMyTask, spec);
}

/// Makes sure things are working in a simple setting.
/// No interceptions, changes, ...
Future testCustomTask() {
  var testCompleter = new Completer();
  asyncStart();

  Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
      TaskCreate create, TaskSpecification specification) {
    if (specification is MySpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-value: ${specification.value} "
          "spec-oneshot?: ${specification.isOneShot}");
      MyTask result = parent.createTask(zone, create, specification);
      log.add("create leave");
      return result;
    }
    return parent.createTask(zone, create, specification);
  }

  void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
      Object task, Object arg) {
    if (task is MyTask) {
      log.add("run enter "
          "zone: ${self['name']} "
          "task-id: ${task.id} "
          "invocation-count: ${task.invocationCount} "
          "arg: $arg");
      parent.runTask(zone, run, task, arg);
      log.add("run leave invocation-count: ${task.invocationCount}");
      return;
    }
    parent.runTask(zone, run, task, arg);
  }

  runZoned(() async {
    var completer0 = new Completer();
    startTask(() {
      completer0.complete("done");
    }, true, 0);
    await completer0.future;

    Expect.listEquals([
      'create enter zone: custom zone spec-value: 0 spec-oneshot?: true',
      'creating task: 0 oneshot?: true',
      'create leave',
      'run enter zone: custom zone task-id: 0 invocation-count: 0 arg: 0',
      'running zone: custom zone task-id: 0 invocation-count: 0 value: 0',
      'run leave invocation-count: 1'
    ], log);
    log.clear();

    var completer1 = new Completer();
    MyTask task1;
    task1 = startTask(() {
      if (task1.invocationCount == 1) {
        task1.shouldStop = true;
        completer1.complete("done");
      }
    }, false, 1);
    await completer1.future;

    Expect.listEquals([
      'create enter zone: custom zone spec-value: 1 spec-oneshot?: false',
      'creating task: 1 oneshot?: false',
      'create leave',
      'run enter zone: custom zone task-id: 1 invocation-count: 0 arg: 1',
      'running zone: custom zone task-id: 1 invocation-count: 0 value: 1',
      'run leave invocation-count: 1',
      'run enter zone: custom zone task-id: 1 invocation-count: 1 arg: 1',
      'running zone: custom zone task-id: 1 invocation-count: 1 value: 1',
      'run leave invocation-count: 2',
    ], log);
    log.clear();

    testCompleter.complete("done");
    asyncEnd();
  },
      zoneValues: {'name': 'custom zone'},
      zoneSpecification: new ZoneSpecification(
          createTask: createTaskHandler,
          runTask: runTaskHandler));

  return testCompleter.future;
}

/// More complicated zone, that intercepts...
Future testCustomTask2() {
  var testCompleter = new Completer();
  asyncStart();

  Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
      TaskCreate create, TaskSpecification specification) {
    if (specification is MySpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-value: ${specification.value} "
          "spec-oneshot?: ${specification.isOneShot}");
      var replacement = new MySpecification(specification.callback,
          specification.isOneShot, specification.value + 1);
      MyTask result = parent.createTask(zone, create, replacement);
      log.add("create leave");
      return result;
    }
    return parent.createTask(zone, create, specification);
  }

  void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
      Object task, Object arg) {
    if (task is MyTask) {
      log.add("run enter "
          "zone: ${self['name']} "
          "task-id: ${task.id} "
          "invocation-count: ${task.invocationCount} "
          "arg: $arg");
      int value = arg;
      parent.runTask(zone, run, task, value + 101);
      log.add("run leave invocation-count: ${task.invocationCount}");
      return;
    }
    parent.runTask(zone, run, task, arg);
  }

  runZoned(() async {
    var completer0 = new Completer();
    startTask(() {
      completer0.complete("done");
    }, true, 0);
    await completer0.future;

    Expect.listEquals([
      'create enter zone: outer-zone spec-value: 0 spec-oneshot?: true',
      'creating task: 1 oneshot?: true',
      'create leave',
      'run enter zone: outer-zone task-id: 1 invocation-count: 0 arg: 1',
      'running zone: outer-zone task-id: 1 invocation-count: 0 value: 102',
      'run leave invocation-count: 1'
    ], log);
    log.clear();

    var completer1 = new Completer();
    MyTask task1;
    task1 = startTask(() {
      if (task1.invocationCount == 1) {
        task1.shouldStop = true;
        completer1.complete("done");
      }
    }, false, 1);
    await completer1.future;

    Expect.listEquals([
      'create enter zone: outer-zone spec-value: 1 spec-oneshot?: false',
      'creating task: 2 oneshot?: false',
      'create leave',
      'run enter zone: outer-zone task-id: 2 invocation-count: 0 arg: 2',
      'running zone: outer-zone task-id: 2 invocation-count: 0 value: 103',
      'run leave invocation-count: 1',
      'run enter zone: outer-zone task-id: 2 invocation-count: 1 arg: 2',
      'running zone: outer-zone task-id: 2 invocation-count: 1 value: 103',
      'run leave invocation-count: 2',
    ], log);
    log.clear();

    var nestedCompleter = new Completer();

    runZoned(() async {
      var completer0 = new Completer();
      startTask(() {
        completer0.complete("done");
      }, true, 0);
      await completer0.future;

      Expect.listEquals([
        'create enter zone: inner-zone spec-value: 0 spec-oneshot?: true',
        'create enter zone: outer-zone spec-value: 1 spec-oneshot?: true',
        'creating task: 2 oneshot?: true',
        'create leave',
        'create leave',
        'run enter zone: inner-zone task-id: 2 invocation-count: 0 arg: 2',
        'run enter zone: outer-zone task-id: 2 invocation-count: 0 arg: 103',
        'running zone: inner-zone task-id: 2 invocation-count: 0 value: 204',
        'run leave invocation-count: 1',
        'run leave invocation-count: 1'
      ], log);
      log.clear();

      var completer1 = new Completer();
      MyTask task1;
      task1 = startTask(() {
        if (task1.invocationCount == 1) {
          task1.shouldStop = true;
          completer1.complete("done");
        }
      }, false, 1);
      await completer1.future;

      Expect.listEquals([
        'create enter zone: inner-zone spec-value: 1 spec-oneshot?: false',
        'create enter zone: outer-zone spec-value: 2 spec-oneshot?: false',
        'creating task: 3 oneshot?: false',
        'create leave',
        'create leave',
        'run enter zone: inner-zone task-id: 3 invocation-count: 0 arg: 3',
        'run enter zone: outer-zone task-id: 3 invocation-count: 0 arg: 104',
        'running zone: inner-zone task-id: 3 invocation-count: 0 value: 205',
        'run leave invocation-count: 1',
        'run leave invocation-count: 1',
        'run enter zone: inner-zone task-id: 3 invocation-count: 1 arg: 3',
        'run enter zone: outer-zone task-id: 3 invocation-count: 1 arg: 104',
        'running zone: inner-zone task-id: 3 invocation-count: 1 value: 205',
        'run leave invocation-count: 2',
        'run leave invocation-count: 2',
      ], log);
      log.clear();

      nestedCompleter.complete("done");
    },
        zoneValues: {'name': 'inner-zone'},
        zoneSpecification: new ZoneSpecification(
            createTask: createTaskHandler,
            runTask: runTaskHandler));

    await nestedCompleter.future;
    testCompleter.complete("done");
    asyncEnd();
  },
      zoneValues: {'name': 'outer-zone'},
      zoneSpecification: new ZoneSpecification(
          createTask: createTaskHandler,
          runTask: runTaskHandler));

  return testCompleter.future;
}

runTests() async {
  await testCustomTask();
  await testCustomTask2();
}

main() {
  asyncStart();
  runTests().then((_) {
    asyncEnd();
  });
}
