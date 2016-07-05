// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventTaskZoneTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:async';
import 'dart:html';

// Tests zone tasks with window.requestAnimationFrame.

class MockAnimationFrameTask implements AnimationFrameTask {
  static int taskId = 499;

  final int id;
  final Zone zone;
  bool _isCanceled = false;
  Function _callback;

  MockAnimationFrameTask(
      this.id, this.zone, this._callback);

  void cancel(Window window) {
    _isCanceled = true;
  }

  trigger(num stamp) {
    zone.runTask(run, this, stamp);
  }

  static create(AnimationFrameRequestSpecification spec, Zone zone) {
    var callback = zone.registerUnaryCallback(spec.callback);
    return new MockAnimationFrameTask(
        taskId++, zone, callback);
  }

  static run(MockAnimationFrameTask task, num arg) {
    AnimationFrameTask.removeMapping(task.id);
    task._callback(arg);
  }
}

animationFrameTest() {
  test("animationFrameTest - no intercept", () async {
    AnimationFrameTask lastTask;
    bool sawRequest = false;
    int id;
    num providedArg;

    Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
        TaskCreate create, TaskSpecification specification) {
      if (specification is AnimationFrameRequestSpecification) {
        sawRequest = true;
        lastTask = parent.createTask(zone, create, specification);
        id = lastTask.id;
        return lastTask;
      }
      return parent.createTask(zone, create, specification);
    }

    void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
        Object task, Object arg) {
      if (identical(task, lastTask)) {
        providedArg = arg;
      }
      parent.runTask(zone, run, task, arg);
    }

    var completer = new Completer();
    var publicId;
    runZoned(() {
      publicId = window.requestAnimationFrame((num stamp) {
        completer.complete(stamp);
      });
    },
        zoneSpecification: new ZoneSpecification(
            createTask: createTaskHandler, runTask: runTaskHandler));

    var referenceCompleter = new Completer();
    window.requestAnimationFrame((num stamp) {
      referenceCompleter.complete(stamp);
    });

    var callbackStamp = await completer.future;
    var referenceStamp = await referenceCompleter.future;

    expect(callbackStamp, equals(referenceStamp));
    expect(providedArg, equals(callbackStamp));
    expect(sawRequest, isTrue);
    expect(publicId, isNotNull);
    expect(publicId, equals(id));
  });
}

interceptedAnimationFrameTest() {
  test("animationFrameTest - intercepted", () {
    List<MockAnimationFrameTask> tasks = [];
    List<num> loggedRuns = [];
    int executedTaskId;
    num executedStamp;

    Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
        TaskCreate create, TaskSpecification specification) {
      if (specification is AnimationFrameRequestSpecification) {
        var task = parent.createTask(
            zone, MockAnimationFrameTask.create, specification);
        tasks.add(task);
        return task;
      }
      return parent.createTask(zone, create, specification);
    }

    void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
        Object task, Object arg) {
      if (tasks.contains(task)) {
        loggedRuns.add(arg);
      }
      parent.runTask(zone, run, task, arg);
    }

    var id0, id1, id2;

    runZoned(() {
      id0 = window.requestAnimationFrame((num stamp) {
        executedTaskId = id0;
        executedStamp = stamp;
      });
      id1 = window.requestAnimationFrame((num stamp) {
        executedTaskId = id1;
        executedStamp = stamp;
      });
      id2 = window.requestAnimationFrame((num stamp) {
        executedTaskId = id2;
        executedStamp = stamp;
      });
    },
        zoneSpecification: new ZoneSpecification(
            createTask: createTaskHandler, runTask: runTaskHandler));

    expect(tasks.length, 3);
    expect(executedTaskId, isNull);
    expect(executedStamp, isNull);
    expect(loggedRuns.isEmpty, isTrue);

    tasks[0].trigger(123.1);
    expect(executedTaskId, id0);
    expect(executedStamp, 123.1);

    tasks[1].trigger(123.2);
    expect(executedTaskId, id1);
    expect(executedStamp, 123.2);

    expect(loggedRuns, equals([123.1, 123.2]));

    window.cancelAnimationFrame(id2);
    expect(tasks[2]._isCanceled, isTrue);
    // Cancel it a second time. Should not crash.
    window.cancelAnimationFrame(id2);
    expect(tasks[2]._isCanceled, isTrue);
  });
}

main() {
  useHtmlConfiguration();

  animationFrameTest();
  interceptedAnimationFrameTest();
}
