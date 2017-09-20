// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.tasks;

import 'dart:async'
    show Future, Zone, ZoneDelegate, ZoneSpecification, runZoned;

/// Used to measure where time is spent in the compiler.
///
/// This exposes [measure] and [measureIo], which wrap an action and associate
/// the time spent during that action with this task. Nested measurementsccan be
/// introduced by using [measureSubtask].
// TODO(sigmund): rename to MeasurableTask
abstract class CompilerTask {
  final Measurer measurer;
  final Stopwatch _watch;
  final Map<String, GenericTask> _subtasks = <String, GenericTask>{};

  int asyncCount = 0;

  // Each task has a fixed, lazily computed, ZoneSpecification and zoneValues
  // for [_measureZoned].
  ZoneSpecification _zoneSpecification;
  Map _zoneValues;

  CompilerTask(Measurer measurer)
      : measurer = measurer,
        _watch = measurer.enableTaskMeasurements ? new Stopwatch() : null;

  /// Whether measurement is disabled. The functions [measure] and [measureIo]
  /// only measure time if measurements are enabled.
  bool get _isDisabled => _watch == null;

  /// Name to use for reporting timing information. Subclasses should override
  /// this with a proper name, otherwise we use the runtime type of the task.
  String get name => "Unknown task '${this.runtimeType}'";

  bool get isRunning => _watch?.isRunning == true;

  int get timing {
    if (_isDisabled) return 0;
    int total = _watch.elapsedMilliseconds;
    for (GenericTask subtask in _subtasks.values) {
      total += subtask.timing;
    }
    return total;
  }

  Duration get duration {
    if (_isDisabled) return Duration.ZERO;
    Duration total = _watch.elapsed;
    for (GenericTask subtask in _subtasks.values) {
      total += subtask.duration;
    }
    return total;
  }

  /// Perform [action] and measure its runtime (including any asynchronous
  /// callbacks, such as, [Future.then], but excluding code measured by other
  /// tasks).
  measure(action()) => _isDisabled ? action() : _measureZoned(action);

  /// Helper method that starts measuring with this [CompilerTask], that is,
  /// make this task the currently measured task.
  CompilerTask _start() {
    if (_isDisabled) return null;
    CompilerTask previous = measurer.currentTask;
    measurer.currentTask = this;
    if (previous != null) previous._watch.stop();
    // Regardless of whether [previous] is `null` we've returned from the
    // eventloop.
    measurer.stopAsyncWallClock();
    _watch.start();
    return previous;
  }

  /// Helper method that stops measuring with this [CompilerTask], that is,
  /// make [previous] the currently measured task.
  void _stop(CompilerTask previous) {
    if (_isDisabled) return;
    _watch.stop();
    if (previous != null) {
      previous._watch.start();
    } else {
      // If there's no previous task, we're about to return control to the
      // event loop. Start counting that as waiting asynchronous I/O.
      measurer.startAsyncWallClock();
    }
    measurer.currentTask = previous;
  }

  _measureZoned(action()) {
    // Using zones, we're able to track asynchronous operations correctly, as
    // our zone will be asked to invoke `then` blocks. Then blocks (the closure
    // passed to runZoned, and other closures) are run via the `run` functions
    // below.

    assert(_watch != null);

    // The current zone is already measuring `this` task.
    if (Zone.current[measurer] == this) return action();

    return runZoned(action,
        zoneValues: _zoneValues ??= {measurer: this},
        zoneSpecification: _zoneSpecification ??= new ZoneSpecification(
            run: _run, runUnary: _runUnary, runBinary: _runBinary));
  }

  /// Run [f] in [zone]. Running must be delegated to [parent] to ensure that
  /// various state is set up correctly (in particular that `Zone.current`
  /// has the right value). Since [_measureZoned] can be called recursively
  /// (synchronously), some of the measuring zones we create will be parents
  /// of other measuring zones, but we still need to call through the parent
  /// chain. Consequently, we use a zone value keyed by [measurer] to see if
  /// we should measure or not when delegating.
  R _run<R>(Zone self, ZoneDelegate parent, Zone zone, R f()) {
    if (zone[measurer] != this) return parent.run(zone, f);
    CompilerTask previous = _start();
    try {
      return parent.run(zone, f);
    } finally {
      _stop(previous);
    }
  }

  /// Same as [run] except that [f] takes one argument, [arg].
  R _runUnary<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R f(T arg), T arg) {
    if (zone[measurer] != this) return parent.runUnary(zone, f, arg);
    CompilerTask previous = _start();
    try {
      return parent.runUnary(zone, f, arg);
    } finally {
      _stop(previous);
    }
  }

  /// Same as [run] except that [f] takes two arguments ([a1] and [a2]).
  R _runBinary<R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R f(T1 a1, T2 a2), T1 a1, T2 a2) {
    if (zone[measurer] != this) return parent.runBinary(zone, f, a1, a2);
    CompilerTask previous = _start();
    try {
      return parent.runBinary(zone, f, a1, a2);
    } finally {
      _stop(previous);
    }
  }

  /// Asynchronous version of [measure]. Use this when action returns a future
  /// that's truly asynchronous, such I/O. Only one task can use this method
  /// concurrently.
  ///
  /// Note: we assume that this method is used only by the compiler input
  /// provider, but it could be used by other tasks as long as the input
  /// provider will not be called by those tasks.
  measureIo(Future action()) {
    if (_isDisabled) return action();

    if (measurer.currentAsyncTask == null) {
      measurer.currentAsyncTask = this;
    } else if (measurer.currentAsyncTask != this) {
      throw "Can't track async task '$name' because"
          " '${measurer.currentAsyncTask.name}' is already being tracked.";
    }
    asyncCount++;
    return measure(action).whenComplete(() {
      asyncCount--;
      if (asyncCount == 0) measurer.currentAsyncTask = null;
    });
  }

  /// Measure the time spent in [action] (if in verbose mode) and accumulate it
  /// under a subtask with the given name.
  measureSubtask(String name, action()) {
    if (_isDisabled) return action();

    // Use a nested CompilerTask for the measurement to ensure nested [measure]
    // calls work correctly. The subtasks will never themselves have nested
    // subtasks because they are not accessible outside.
    GenericTask subtask =
        _subtasks.putIfAbsent(name, () => new GenericTask(name, measurer));
    return subtask.measure(action);
  }

  Iterable<String> get subtasks => _subtasks.keys;

  int getSubtaskTime(String subtask) => _subtasks[subtask].timing;

  bool getSubtaskIsRunning(String subtask) => _subtasks[subtask].isRunning;
}

class GenericTask extends CompilerTask {
  final String name;
  GenericTask(this.name, Measurer measurer) : super(measurer);
}

class Measurer {
  /// Measures the total runtime from this object was constructed.
  ///
  /// Note: MUST be the first field of this class to ensure [wallclock] is
  /// started before other computations.
  final Stopwatch wallClock = new Stopwatch()..start();

  /// Measures gaps between zoned closures due to asynchronicity.
  final Stopwatch asyncWallClock = new Stopwatch();

  /// Whether measurement of tasks is enabled.
  final bool enableTaskMeasurements;

  static int _hashCodeGenerator = 197;
  final int hashCode = _hashCodeGenerator++;

  Measurer({this.enableTaskMeasurements: false});

  /// The currently running task, that is, the task whose [Stopwatch] is
  /// currently running.
  CompilerTask currentTask;

  /// The current task which should be charged for asynchronous gaps.
  CompilerTask currentAsyncTask;

  /// Start counting the total elapsed time since the compiler started.
  void startWallClock() {
    wallClock.start();
  }

  /// Start counting the total elapsed time since the compiler started.
  void stopWallClock() {
    wallClock.stop();
  }

  /// Call this before returning to the eventloop.
  void startAsyncWallClock() {
    if (currentAsyncTask != null) {
      currentAsyncTask._watch.start();
    } else {
      asyncWallClock.start();
    }
  }

  /// Call this when the eventloop returns control to us.
  void stopAsyncWallClock() {
    if (currentAsyncTask != null) {
      currentAsyncTask._watch.stop();
    }
    asyncWallClock.stop();
  }
}
