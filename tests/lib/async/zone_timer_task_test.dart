// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests timer tasks.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'dart:collection';

class MyTimerSpecification implements SingleShotTimerTaskSpecification {
  final Function callback;
  final Duration duration;

  MyTimerSpecification(this.callback, this.duration);

  bool get isOneShot => true;
  String get name => "test.timer-override";
}

class MyPeriodicTimerSpecification implements PeriodicTimerTaskSpecification {
  final Function callback;
  final Duration duration;

  MyPeriodicTimerSpecification(this.callback, this.duration);

  bool get isOneShot => true;
  String get name => "test.periodic-timer-override";
}

/// Makes sure things are working in a simple setting.
/// No interceptions, changes, ...
Future testTimerTask() {
  List log = [];

  var testCompleter = new Completer();
  asyncStart();

  int taskIdCounter = 0;

  Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
      TaskCreate create, TaskSpecification specification) {
    var taskMap = self['taskMap'];
    var taskIdMap = self['taskIdMap'];
    if (specification is SingleShotTimerTaskSpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-duration: ${specification.duration} "
          "spec-oneshot?: ${specification.isOneShot}");
      var result = parent.createTask(zone, create, specification);
      taskMap[result] = specification;
      taskIdMap[specification] = taskIdCounter++;
      log.add("create leave");
      return result;
    } else if (specification is PeriodicTimerTaskSpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-duration: ${specification.duration} "
          "spec-oneshot?: ${specification.isOneShot}");
      var result = parent.createTask(zone, create, specification);
      taskMap[result] = specification;
      taskIdMap[specification] = taskIdCounter++;
      log.add("create leave");
      return result;
    }
    return parent.createTask(zone, create, specification);
  }

  void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
      Object task, Object arg) {
    var taskMap = self['taskMap'];
    var taskIdMap = self['taskIdMap'];
    if (taskMap.containsKey(task)) {
      var spec = taskMap[task];
      log.add("run enter "
          "zone: ${self['name']} "
          "task-id: ${taskIdMap[spec]} "
          "arg: $arg");
      parent.runTask(zone, run, task, arg);
      log.add("run leave");
      return;
    }
    parent.runTask(zone, run, task, arg);
  }

  runZoned(() async {
    var completer0 = new Completer();
    Timer.run(() {
      completer0.complete("done");
    });
    await completer0.future;

    Expect.listEquals([
      'create enter zone: custom zone spec-duration: 0:00:00.000000 '
          'spec-oneshot?: true',
      'create leave',
      'run enter zone: custom zone task-id: 0 arg: null',
      'run leave'
    ], log);
    log.clear();

    var completer1 = new Completer();
    var counter1 = 0;
    new Timer.periodic(const Duration(milliseconds: 5), (Timer timer) {
      if (counter1++ > 1) {
        timer.cancel();
        completer1.complete("done");
      }
    });
    await completer1.future;

    Expect.listEquals([
      'create enter zone: custom zone spec-duration: 0:00:00.005000 '
          'spec-oneshot?: false',
      'create leave',
      'run enter zone: custom zone task-id: 1 arg: null',
      'run leave',
      'run enter zone: custom zone task-id: 1 arg: null',
      'run leave',
      'run enter zone: custom zone task-id: 1 arg: null',
      'run leave'
    ], log);
    log.clear();

    testCompleter.complete("done");
    asyncEnd();
  },
      zoneValues: {'name': 'custom zone', 'taskMap': {}, 'taskIdMap': {}},
      zoneSpecification: new ZoneSpecification(
          createTask: createTaskHandler,
          runTask: runTaskHandler));

  return testCompleter.future;
}

/// More complicated zone, that intercepts...
Future testTimerTask2() {
  List log = [];

  var testCompleter = new Completer();
  asyncStart();

  int taskIdCounter = 0;

  Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
      TaskCreate create, TaskSpecification specification) {
    var taskMap = self['taskMap'];
    var taskIdMap = self['taskIdMap'];
    if (specification is SingleShotTimerTaskSpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-duration: ${specification.duration} "
          "spec-oneshot?: ${specification.isOneShot}");
      var mySpec = new MyTimerSpecification(specification.callback,
          specification.duration + const Duration(milliseconds: 2));
      var result = parent.createTask(zone, create, mySpec);
      taskMap[result] = specification;
      taskIdMap[specification] = taskIdCounter++;
      log.add("create leave");
      return result;
    } else if (specification is PeriodicTimerTaskSpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-duration: ${specification.duration} "
          "spec-oneshot?: ${specification.isOneShot}");
      var mySpec = new MyPeriodicTimerSpecification(specification.callback,
          specification.duration + const Duration(milliseconds: 2));
      var result = parent.createTask(zone, create, specification);
      taskMap[result] = specification;
      taskIdMap[specification] = taskIdCounter++;
      log.add("create leave");
      return result;
    }
    return parent.createTask(zone, create, specification);
  }

  void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
      Object task, Object arg) {
    var taskMap = self['taskMap'];
    var taskIdMap = self['taskIdMap'];
    if (taskMap.containsKey(task)) {
      var spec = taskMap[task];
      log.add("run enter "
          "zone: ${self['name']} "
          "task-id: ${taskIdMap[spec]} "
          "arg: $arg");
      parent.runTask(zone, run, task, arg);
      log.add("run leave");
      return;
    }
    parent.runTask(zone, run, task, arg);
  }

  runZoned(() async {
    var completer0 = new Completer();
    Timer.run(() {
      completer0.complete("done");
    });
    await completer0.future;

    // No visible change (except for the zone name) in the log, compared to the
    // simple invocations.
    Expect.listEquals([
      'create enter zone: outer-zone spec-duration: 0:00:00.000000 '
          'spec-oneshot?: true',
      'create leave',
      'run enter zone: outer-zone task-id: 0 arg: null',
      'run leave'
    ], log);
    log.clear();

    var completer1 = new Completer();
    var counter1 = 0;
    new Timer.periodic(const Duration(milliseconds: 5), (Timer timer) {
      if (counter1++ > 1) {
        timer.cancel();
        completer1.complete("done");
      }
    });
    await completer1.future;

    // No visible change (except for the zone nome) in the log, compared to the
    // simple invocations.
    Expect.listEquals([
      'create enter zone: outer-zone spec-duration: 0:00:00.005000 '
          'spec-oneshot?: false',
      'create leave',
      'run enter zone: outer-zone task-id: 1 arg: null',
      'run leave',
      'run enter zone: outer-zone task-id: 1 arg: null',
      'run leave',
      'run enter zone: outer-zone task-id: 1 arg: null',
      'run leave'
    ], log);
    log.clear();

    var nestedCompleter = new Completer();

    runZoned(() async {
      var completer0 = new Completer();
      Timer.run(() {
        completer0.complete("done");
      });
      await completer0.future;

      // The outer zone sees the duration change of the inner zone.
      Expect.listEquals([
        'create enter zone: inner-zone spec-duration: 0:00:00.000000 '
            'spec-oneshot?: true',
        'create enter zone: outer-zone spec-duration: 0:00:00.002000 '
            'spec-oneshot?: true',
        'create leave',
        'create leave',
        'run enter zone: inner-zone task-id: 3 arg: null',
        'run enter zone: outer-zone task-id: 2 arg: null',
        'run leave',
        'run leave'
      ], log);
      log.clear();

      var completer1 = new Completer();
      var counter1 = 0;
      new Timer.periodic(const Duration(milliseconds: 5), (Timer timer) {
        if (counter1++ > 1) {
          timer.cancel();
          completer1.complete("done");
        }
      });
      await completer1.future;

      // The outer zone sees the duration change of the inner zone.
      Expect.listEquals([
        'create enter zone: inner-zone spec-duration: 0:00:00.005000 '
            'spec-oneshot?: false',
        'create enter zone: outer-zone spec-duration: 0:00:00.005000 '
            'spec-oneshot?: false',
        'create leave',
        'create leave',
        'run enter zone: inner-zone task-id: 5 arg: null',
        'run enter zone: outer-zone task-id: 4 arg: null',
        'run leave',
        'run leave',
        'run enter zone: inner-zone task-id: 5 arg: null',
        'run enter zone: outer-zone task-id: 4 arg: null',
        'run leave',
        'run leave',
        'run enter zone: inner-zone task-id: 5 arg: null',
        'run enter zone: outer-zone task-id: 4 arg: null',
        'run leave',
        'run leave'
      ], log);
      log.clear();

      nestedCompleter.complete("done");
    },
        zoneValues: {'name': 'inner-zone', 'taskMap': {}, 'taskIdMap': {}},
        zoneSpecification: new ZoneSpecification(
            createTask: createTaskHandler,
            runTask: runTaskHandler));

    await nestedCompleter.future;
    testCompleter.complete("done");
    asyncEnd();
  },
      zoneValues: {'name': 'outer-zone', 'taskMap': {}, 'taskIdMap': {}},
      zoneSpecification: new ZoneSpecification(
          createTask: createTaskHandler,
          runTask: runTaskHandler));

  return testCompleter.future;
}

class TimerEntry {
  final int time;
  final SimulatedTimer timer;

  TimerEntry(this.time, this.timer);
}

class SimulatedTimer implements Timer {
  static int _idCounter = 0;

  Zone _zone;
  final int _id = _idCounter++;
  final Duration _duration;
  final Function _callback;
  final bool _isPeriodic;
  bool _isActive = true;

  SimulatedTimer(this._zone, this._duration, this._callback, this._isPeriodic);

  bool get isActive => _isActive;

  void cancel() {
    _isActive = false;
  }

  void _run() {
    if (!isActive) return;
    _zone.runTask(_runTimer, this, null);
  }

  static void _runTimer(SimulatedTimer timer, _) {
    if (timer._isPeriodic) {
      timer._callback(timer);
    } else {
      timer._callback();
    }
  }
}

testSimulatedTimer() {
  List log = [];

  var currentTime = 0;
  // Using a simple list as queue. Not very efficient, but the test has only
  // very few timers running at the same time.
  var queue = new DoubleLinkedQueue<TimerEntry>();

  // Schedules the given callback at now + duration.
  void schedule(int scheduledTime, SimulatedTimer timer) {
    log.add("scheduling timer ${timer._id} for $scheduledTime");
    if (queue.isEmpty) {
      queue.add(new TimerEntry(scheduledTime, timer));
    } else {
      DoubleLinkedQueueEntry current = queue.firstEntry();
      while (current != null) {
        if (current.element.time <= scheduledTime) {
          current = current.nextEntry();
        } else {
          current.prepend(new TimerEntry(scheduledTime, timer));
          break;
        }
      }
      if (current == null) {
        queue.add(new TimerEntry(scheduledTime, timer));
      }
    }
  }

  void runQueue() {
    while (queue.isNotEmpty) {
      var item = queue.removeFirst();
      // If multiple callbacks were scheduled at the same time, increment the
      // current time instead of staying at the same time.
      currentTime = item.time > currentTime ? item.time : currentTime + 1;
      SimulatedTimer timer = item.timer;
      log.add("running timer ${timer._id} at $currentTime "
          "(active?: ${timer.isActive})");
      if (!timer.isActive) continue;
      if (timer._isPeriodic) {
        schedule(currentTime + timer._duration.inMilliseconds, timer);
      }
      item.timer._run();
    }
  }

  SimulatedTimer createSimulatedOneShotTimer(
      SingleShotTimerTaskSpecification spec, Zone zone) {
    var timer = new SimulatedTimer(zone, spec.duration, spec.callback, false);
    schedule(currentTime + spec.duration.inMilliseconds, timer);
    return timer;
  }

  SimulatedTimer createSimulatedPeriodicTimer(
      PeriodicTimerTaskSpecification spec, Zone zone) {
    var timer = new SimulatedTimer(zone, spec.duration, spec.callback, true);
    schedule(currentTime + spec.duration.inMilliseconds, timer);
    return timer;
  }

  Object createSimulatedTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
      TaskCreate create, TaskSpecification specification) {
    var taskMap = self['taskMap'];
    var taskIdMap = self['taskIdMap'];
    if (specification is SingleShotTimerTaskSpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-duration: ${specification.duration} "
          "spec-oneshot?: ${specification.isOneShot}");
      var result =
          parent.createTask(zone, createSimulatedOneShotTimer, specification);
      log.add("create leave");
      return result;
    }
    if (specification is PeriodicTimerTaskSpecification) {
      log.add("create enter "
          "zone: ${self['name']} "
          "spec-duration: ${specification.duration} "
          "spec-oneshot?: ${specification.isOneShot}");
      var result =
          parent.createTask(zone, createSimulatedPeriodicTimer, specification);
      log.add("create leave");
      return result;
    }
    return parent.createTask(zone, create, specification);
  }

  runZoned(() {
    Timer.run(() {
      log.add("running Timer.run");
    });

    var timer0;

    new Timer(const Duration(milliseconds: 10), () {
      log.add("running Timer(10)");
      timer0.cancel();
      log.add("canceled timer0");
    });

    timer0 = new Timer(const Duration(milliseconds: 15), () {
      log.add("running Timer(15)");
    });

    var counter1 = 0;
    new Timer.periodic(const Duration(milliseconds: 5), (Timer timer) {
      log.add("running periodic timer $counter1");
      if (counter1++ > 1) {
        timer.cancel();
      }
    });
  },
      zoneSpecification:
          new ZoneSpecification(createTask: createSimulatedTaskHandler));

  runQueue();

  Expect.listEquals([
    'create enter zone: null spec-duration: 0:00:00.000000 spec-oneshot?: true',
    'scheduling timer 0 for 0',
    'create leave',
    'create enter zone: null spec-duration: 0:00:00.010000 spec-oneshot?: true',
    'scheduling timer 1 for 10',
    'create leave',
    'create enter zone: null spec-duration: 0:00:00.015000 spec-oneshot?: true',
    'scheduling timer 2 for 15',
    'create leave',
    'create enter zone: null spec-duration: 0:00:00.005000 '
        'spec-oneshot?: false',
    'scheduling timer 3 for 5',
    'create leave',
    'running timer 0 at 1 (active?: true)',
    'running Timer.run',
    'running timer 3 at 5 (active?: true)',
    'scheduling timer 3 for 10',
    'running periodic timer 0',
    'running timer 1 at 10 (active?: true)',
    'running Timer(10)',
    'canceled timer0',
    'running timer 3 at 11 (active?: true)',
    'scheduling timer 3 for 16',
    'running periodic timer 1',
    'running timer 2 at 15 (active?: false)',
    'running timer 3 at 16 (active?: true)',
    'scheduling timer 3 for 21',
    'running periodic timer 2',
    'running timer 3 at 21 (active?: false)'
  ], log);
  log.clear();
}

runTests() async {
  await testTimerTask();
  await testTimerTask2();
  testSimulatedTimer();
}

main() {
  asyncStart();
  runTests().then((_) {
    asyncEnd();
  });
}
