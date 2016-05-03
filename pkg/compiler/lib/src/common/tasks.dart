// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.tasks;

import 'dart:async'
    show Future, Zone, ZoneDelegate, ZoneSpecification, runZoned;

import '../common.dart';
import '../compiler.dart' show Compiler;
import '../elements/elements.dart' show Element;

typedef void DeferredAction();

class DeferredTask {
  final Element element;
  final DeferredAction action;

  DeferredTask(this.element, this.action);
}

/// A [CompilerTask] is used to measure where time is spent in the compiler.
/// The main entry points are [measure] and [measureIo].
class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;
  final Map<String, GenericTask> _subtasks = <String, GenericTask>{};

  int asyncCount = 0;

  CompilerTask(Compiler compiler)
      : this.compiler = compiler,
        watch = (compiler.options.verbose) ? new Stopwatch() : null;

  DiagnosticReporter get reporter => compiler.reporter;

  Measurer get measurer => compiler.measurer;

  String get name => "Unknown task '${this.runtimeType}'";

  bool get isRunning => watch?.isRunning == true;

  int get timing {
    if (watch == null) return 0;
    int total = watch.elapsedMilliseconds;
    for (GenericTask subtask in _subtasks.values) {
      total += subtask.timing;
    }
    return total;
  }

  Duration get duration {
    if (watch == null) return Duration.ZERO;
    Duration total = watch.elapsed;
    for (GenericTask subtask in _subtasks.values) {
      total += subtask.duration;
    }
    return total;
  }

  /// Perform [action] and use [watch] to measure its runtime (including any
  /// asynchronous callbacks, such as, [Future.then], but excluding code
  /// measured by other tasks).
  measure(action()) => watch == null ? action() : measureZoned(action);

  /// Helper method that starts measuring with this [CompilerTask], that is,
  /// make this task the currently measured task.
  CompilerTask start() {
    if (watch == null) return null;
    CompilerTask previous = measurer.currentTask;
    measurer.currentTask = this;
    if (previous != null) previous.watch.stop();
    // Regardless of whether [previous] is `null` we've returned from the
    // eventloop.
    measurer.stopAsyncWallClock();
    watch.start();
    return previous;
  }

  /// Helper method that stops measuring with this [CompilerTask], that is,
  /// make [previous] the currently measured task.
  void stop(CompilerTask previous) {
    if (watch == null) return;
    watch.stop();
    if (previous != null) {
      previous.watch.start();
    } else {
      // If there's no previous task, we're about to return control to the
      // event loop. Start counting that as waiting asynchronous I/O.
      measurer.startAsyncWallClock();
    }
    measurer.currentTask = previous;
  }

  /// Helper method for [measure]. Don't call this method directly as it
  /// assumes that [watch] isn't null.
  measureZoned(action()) {
    // Using zones, we're able to track asynchronous operations correctly, as
    // our zone will be asked to invoke `then` blocks. Then blocks (the closure
    // passed to runZoned, and other closures) are run via the `run` functions
    // below.

    assert(watch != null);

    // The current zone is already measuring `this` task.
    if (Zone.current[measurer] == this) return action();

    /// Run [f] in [zone]. Running must be delegated to [parent] to ensure that
    /// various state is set up correctly (in particular that `Zone.current`
    /// has the right value). Since [measureZoned] can be called recursively
    /// (synchronously), some of the measuring zones we create will be parents
    /// of other measuring zones, but we still need to call through the parent
    /// chain. Consequently, we use a zone value keyed by [measurer] to see if
    /// we should measure or not when delegating.
    run(Zone self, ZoneDelegate parent, Zone zone, f()) {
      if (zone[measurer] != this) return parent.run(zone, f);
      CompilerTask previous = start();
      try {
        return parent.run(zone, f);
      } finally {
        stop(previous);
      }
    }

    /// Same as [run] except that [f] takes one argument, [arg].
    runUnary(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg) {
      if (zone[measurer] != this) return parent.runUnary(zone, f, arg);
      CompilerTask previous = start();
      try {
        return parent.runUnary(zone, f, arg);
      } finally {
        stop(previous);
      }
    }

    /// Same as [run] except that [f] takes two arguments ([a1] and [a2]).
    runBinary(Zone self, ZoneDelegate parent, Zone zone, f(a1, a2), a1, a2) {
      if (zone[measurer] != this) return parent.runBinary(zone, f, a1, a2);
      CompilerTask previous = start();
      try {
        return parent.runBinary(zone, f, a1, a2);
      } finally {
        stop(previous);
      }
    }

    return runZoned(action,
        zoneValues: {measurer: this},
        zoneSpecification: new ZoneSpecification(
            run: run, runUnary: runUnary, runBinary: runBinary));
  }

  /// Asynchronous version of [measure]. Use this when action returns a future
  /// that's truly asynchronous, such I/O. Only one task can use this method
  /// concurrently.
  ///
  /// Note: we assume that this method is used only by the compiler input
  /// provider, but it could be used by other tasks as long as the input
  /// provider will not be called by those tasks.
  measureIo(Future action()) {
    return watch == null ? action() : measureIoHelper(action);
  }

  /// Helper method for [measureIo]. Don't call this directly as it assumes
  /// that [watch] isn't null.
  Future measureIoHelper(Future action()) {
    assert(watch != null);
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

  /// Convenience function for combining
  /// [DiagnosticReporter.withCurrentElement] and [measure].
  measureElement(Element element, action()) {
    return watch == null
        ? reporter.withCurrentElement(element, action)
        : measureElementHelper(element, action);
  }

  /// Helper method for [measureElement]. Don't call this directly as it
  /// assumes that [watch] isn't null.
  measureElementHelper(Element element, action()) {
    assert(watch != null);
    return reporter.withCurrentElement(element, () => measure(action));
  }

  /// Measure the time spent in [action] (if in verbose mode) and accumulate it
  /// under a subtask with the given name.
  measureSubtask(String name, action()) {
    return watch == null ? action() : measureSubtaskHelper(name, action);
  }

  /// Helper method for [measureSubtask]. Don't call this directly as it
  /// assumes that [watch] isn't null.
  measureSubtaskHelper(String name, action()) {
    assert(watch != null);
    // Use a nested CompilerTask for the measurement to ensure nested [measure]
    // calls work correctly. The subtasks will never themselves have nested
    // subtasks because they are not accessible outside.
    GenericTask subtask =
        _subtasks.putIfAbsent(name, () => new GenericTask(name, compiler));
    return subtask.measure(action);
  }

  Iterable<String> get subtasks => _subtasks.keys;

  int getSubtaskTime(String subtask) => _subtasks[subtask].timing;

  bool getSubtaskIsRunning(String subtask) => _subtasks[subtask].isRunning;
}

class GenericTask extends CompilerTask {
  final String name;

  GenericTask(this.name, Compiler compiler) : super(compiler);
}

class Measurer {
  /// Measures the total runtime from this object was constructed.
  ///
  /// Note: MUST be first field to ensure [wallclock] is started before other
  /// computations.
  final Stopwatch wallClock = new Stopwatch()..start();

  /// Measures gaps between zoned closures due to asynchronicity.
  final Stopwatch asyncWallClock = new Stopwatch();

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
      currentAsyncTask.watch.start();
    } else {
      asyncWallClock.start();
    }
  }

  /// Call this when the eventloop returns control to us.
  void stopAsyncWallClock() {
    if (currentAsyncTask != null) {
      currentAsyncTask.watch.stop();
    }
    asyncWallClock.stop();
  }
}
