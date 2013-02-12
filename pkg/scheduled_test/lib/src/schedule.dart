// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library schedule;

import 'dart:async';
import 'dart:collection';

import 'package:unittest/unittest.dart' as unittest;

import 'schedule_error.dart';
import 'task.dart';

/// The schedule of tasks to run for a single test. This has three separate task
/// queues: [tasks], [onComplete], and [onException]. It also provides
/// visibility into the current state of the schedule.
class Schedule {
  /// The main task queue for the schedule. These tasks are run before the other
  /// queues and generally constitute the main test body.
  TaskQueue get tasks => _tasks;
  TaskQueue _tasks;

  /// The queue of tasks to run if an error is caught while running [tasks]. The
  /// error will be available via [error]. These tasks won't be run if no error
  /// occurs. Note that expectation failures count as errors.
  ///
  /// This queue runs before [onComplete], and errors in [onComplete] will not
  /// cause this queue to be run.
  ///
  /// If an error occurs in a task in this queue, all further tasks will be
  /// skipped.
  TaskQueue get onException => _onException;
  TaskQueue _onException;

  /// The queue of tasks to run after [tasks] and possibly [onException] have
  /// run. This queue will run whether or not an error occurred. If one did, it
  /// will be available via [error]. Note that expectation failures count as
  /// errors.
  ///
  /// This queue runs after [onException]. If an error occurs while running
  /// [onException], that error will be available via [error] in place of the
  /// original error.
  ///
  /// If an error occurs in a task in this queue, all further tasks will be
  /// skipped.
  TaskQueue get onComplete => _onComplete;
  TaskQueue _onComplete;

  /// Returns the [Task] that's currently executing, or `null` if there is no
  /// such task. This will be `null` both before the schedule starts running and
  /// after it's finished.
  Task get currentTask => _currentTask;
  Task _currentTask;

  /// Whether the schedule has finished running. This is only set once
  /// [onComplete] has finished running. It will be set whether or not an
  /// exception has occurred.
  bool get done => _done;
  bool _done = false;

  /// The error thrown by the task queue. This will only be set while running
  /// [onException] and [onComplete], since an error in [tasks] will cause it to
  /// terminate immediately.
  ScheduleError get error => _error;
  ScheduleError _error;

  /// The task queue that's currently being run, or `null` if there is no such
  /// queue. One of [tasks], [onException], or [onComplete]. This will be `null`
  /// before the schedule starts running.
  TaskQueue get currentQueue => _done ? null : _currentQueue;
  TaskQueue _currentQueue;

  /// The number of out-of-band callbacks that have been registered with
  /// [wrapAsync] but have yet to be called.
  int _pendingCallbacks = 0;

  /// A completer that will be completed once [_pendingCallbacks] reaches zero.
  /// This will only be non-`null` if [_awaitPendingCallbacks] has been called
  /// while [_pendingCallbacks] is non-zero.
  Completer _noPendingCallbacks;

  /// Creates a new schedule with empty task queues.
  Schedule() {
    _tasks = new TaskQueue._("tasks", this);
    _onComplete = new TaskQueue._("onComplete", this);
    _onException = new TaskQueue._("onException", this);
  }

  /// Sets up this schedule by running [setUp], then runs all the task queues in
  /// order. Any errors in [setUp] will cause [onException] to run.
  Future run(void setUp()) {
    return new Future.immediate(null).then((_) {
      try {
        setUp();
      } catch (e, stackTrace) {
        throw new ScheduleError.from(this, e, stackTrace: stackTrace);
      }

      return tasks._run();
    }).catchError((e) {
      _error = e;
      return onException._run().then((_) {
        throw e;
      });
    }).whenComplete(() => onComplete._run()).whenComplete(() {
      _done = true;
    });
  }

  /// Signals that an out-of-band error has occurred. Using [wrapAsync] along
  /// with `throw` is usually preferable to calling this directly.
  ///
  /// The metadata in [AsyncError]s and [ScheduleError]s will be preserved.
  void signalError(error, [stackTrace]) {
    var scheduleError = new ScheduleError.from(this, error,
        stackTrace: stackTrace, task: currentTask);
    if (_done) {
      throw new StateError(
          "An out-of-band error was signaled outside of wrapAsync after the "
              "schedule finished running:"
          "${prefixLines(scheduleError.toString())}");
    } else if (currentQueue == null) {
      // If we're not done but there's no current queue, that means we haven't
      // started yet and thus we're in setUp or the synchronous body of the
      // function. Throwing the error will thus pipe it into the main
      // error-handling code.
      throw scheduleError;
    } else {
      _currentQueue._signalError(scheduleError);
    }
  }

  /// Returns a function wrapping [fn] that pipes any errors into the schedule
  /// chain. This will also block the current task queue from completing until
  /// the returned function has been called. It's used to ensure that
  /// out-of-band callbacks are properly handled by the scheduled test.
  ///
  /// The top-level `wrapAsync` function should usually be used in preference to
  /// this.
  Function wrapAsync(fn(arg)) {
    if (_done) {
      throw new StateError("wrapAsync called after the schedule has finished "
          "running.");
    }

    _pendingCallbacks++;
    return (arg) {
      try {
        return fn(arg);
      } catch (e, stackTrace) {
        signalError(e, stackTrace);
      } finally {
        _pendingCallbacks--;
        if (_pendingCallbacks == 0 && _noPendingCallbacks != null) {
          _noPendingCallbacks.complete();
          _noPendingCallbacks = null;
        }
      }
    };
  }

  /// Returns a [Future] that will complete once there are no pending
  /// out-of-band callbacks.
  Future _awaitNoPendingCallbacks() {
    if (_pendingCallbacks == 0) return new Future.immediate(null);
    if (_noPendingCallbacks == null) _noPendingCallbacks = new Completer();
    return _noPendingCallbacks.future;
  }
}

/// A queue of asynchronous tasks to execute in order.
class TaskQueue {
  // TODO(nweiz): make this a read-only view when issue 8321 is fixed.
  /// The tasks in the queue.
  Collection<Task> get contents => _contents;
  final _contents = new Queue<Task>();

  /// The name of the queue, for debugging purposes.
  final String name;

  /// The [Schedule] that created this queue.
  final Schedule _schedule;

  /// An out-of-band error signaled by [_schedule]. If this is non-null, it
  /// indicates that the queue should stop as soon as possible and re-throw this
  /// error.
  ScheduleError _error;

  TaskQueue._(this.name, this._schedule);

  /// Schedules a task, [fn], to run asynchronously as part of this queue. Tasks
  /// will be run in the order they're scheduled. In [fn] returns a [Future],
  /// tasks after it won't be run until that [Future] completes.
  ///
  /// The return value will be completed once the scheduled task has finished
  /// running. Its return value is the same as the return value of [fn], or the
  /// value it completes to if it's a [Future].
  ///
  /// If [description] is passed, it's used to describe the task for debugging
  /// purposes when an error occurs.
  Future schedule(fn(), [String description]) {
    var task = new Task(fn, this, description);
    _contents.add(task);
    return task.result;
  }

  /// Runs all the tasks in this queue in order.
  Future _run() {
    _schedule._currentQueue = this;
    return Future.forEach(_contents, (task) {
      _schedule._currentTask = task;
      if (_error != null) throw _error;
      return task.fn().catchError((e) {
        throw new ScheduleError.from(_schedule, e, task: task);
      });
    }).whenComplete(() {
      _schedule._currentTask = null;
      return _schedule._awaitNoPendingCallbacks();
    }).then((_) {
      if (_error != null) throw _error;
    });
  }

  /// Signals that an out-of-band error has been detected and the queue should
  /// stop running as soon as possible.
  void _signalError(ScheduleError error) {
    _error = error;
  }

  String toString() => name;

  /// Returns a detailed representation of the queue as a tree of tasks. If
  /// [highlight] is passed, that task is specially highlighted.
  ///
  /// [highlight] must be a task in this queue.
  String generateTree([Task highlight]) {
    assert(highlight == null || highlight.queue == this);
    return _contents.map((task) {
      var lines = task.toString().split("\n");
      var firstLine = task == highlight ?
          "> ${lines.first}" : "* ${lines.first}";
      lines = new List.from(lines.skip(1).map((line) => "| $line"));
      lines.insertRange(0, 1, firstLine);
      return lines.join("\n");
    }).join("\n");
  }
}
