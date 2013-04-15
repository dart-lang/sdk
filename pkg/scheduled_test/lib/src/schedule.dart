// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library schedule;

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart' as unittest;

import 'mock_clock.dart' as mock_clock;
import 'schedule_error.dart';
import 'substitute_future.dart';
import 'task.dart';
import 'utils.dart';
import 'value_future.dart';

/// The schedule of tasks to run for a single test. This has three separate task
/// queues: [tasks], [onComplete], and [onException]. It also provides
/// visibility into the current state of the schedule.
class Schedule {
  /// The main task queue for the schedule. These tasks are run before the other
  /// queues and generally constitute the main test body.
  TaskQueue get tasks => _tasks;
  TaskQueue _tasks;

  /// The queue of tasks to run if an error is caught while running [tasks]. The
  /// error will be available in [errors]. These tasks won't be run if no error
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
  /// will be available in [errors]. Note that expectation failures count as
  /// errors.
  ///
  /// This queue runs after [onException]. If an error occurs while running
  /// [onException], that error will be available in [errors] after the original
  /// error.
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

  /// The current state of the schedule.
  ScheduleState get state => _state;
  ScheduleState _state = ScheduleState.SET_UP;

  // TODO(nweiz): make this a read-only view once issue 8321 is fixed.
  /// Errors thrown by the task queues.
  ///
  /// When running tasks in [tasks], this will always be empty. If an error
  /// occurs in [tasks], it will be added to this list and then [onException]
  /// will be run. If an error occurs there as well, it will be added to this
  /// list and [onComplete] will be run. Errors thrown during [onComplete] will
  /// also be added to this list, although no scheduled tasks will be run
  /// afterwards.
  ///
  /// Any out-of-band callbacks that throw errors will also have those errors
  /// added to this list.
  final errors = <ScheduleError>[];

  // TODO(nweiz): make this a read-only view once issue 8321 is fixed.
  /// Additional debugging info registered via [addDebugInfo].
  final debugInfo = <String>[];

  /// The task queue that's currently being run. One of [tasks], [onException],
  /// or [onComplete]. This starts as [tasks], and can only be `null` after the
  /// schedule is done.
  TaskQueue get currentQueue =>
    _state == ScheduleState.DONE ? null : _currentQueue;
  TaskQueue _currentQueue;

  /// The time to wait before terminating a task queue for inactivity. Defaults
  /// to 5 seconds. This can be set to `null` to disable timeouts entirely. Note
  /// that the timeout is the maximum time a task is allowed between
  /// interactions with the schedule, *not* the maximum time an entire test is
  /// allowed. See also [heartbeat].
  ///
  /// If a task queue times out, an error will be raised that can be handled as
  /// usual in the [onException] and [onComplete] queues. If [onException] times
  /// out, that can only be handled in [onComplete]; if [onComplete] times out,
  /// that cannot be handled.
  ///
  /// If a task times out and then later completes with an error, that error
  /// cannot be handled. The user will still be notified of it.
  Duration get timeout => _timeout;
  Duration _timeout = new Duration(seconds: 5);
  set timeout(Duration duration) {
    _timeout = duration;
    heartbeat();
  }

  /// The timer for keeping track of task timeouts. This may be null.
  Timer _timeoutTimer;

  /// If `true`, then new [Task]s will capture the current stack trace before
  /// running. This can be set to `false` to speed up running tests since
  /// capturing stack traces is currently quite slow. Even when set to `false`,
  /// stack traces from *thrown* exceptions will be caught. This only disables
  /// the eager collection of stack traces *before* an error occurs. Defaults
  /// to `true`.
  bool captureStackTraces = true;

  /// Creates a new schedule with empty task queues.
  Schedule() {
    _tasks = new TaskQueue._("tasks", this);
    _onComplete = new TaskQueue._("onComplete", this);
    _onException = new TaskQueue._("onException", this);
    _currentQueue = _tasks;

    heartbeat();
  }

  /// Sets up this schedule by running [setUp], then runs all the task queues in
  /// order. Any errors in [setUp] will cause [onException] to run.
  Future run(void setUp()) {
    return new Future.value().then((_) {
      try {
        setUp();
      } catch (e, stackTrace) {
        // Even though the scheduling failed, we need to run the onException and
        // onComplete queues, so we set the schedule state to RUNNING.
        _state = ScheduleState.RUNNING;
        throw new ScheduleError.from(this, e, stackTrace: stackTrace);
      }

      _state = ScheduleState.RUNNING;
      return tasks._run();
    }).catchError((e) {
      _addError(e);
      return onException._run().catchError((innerError) {
        // If an error occurs in a task in the onException queue, make sure it's
        // registered in the error list and re-throw it. We could also re-throw
        // `e`; ultimately, all the errors will be shown to the user if any
        // ScheduleError is thrown.
        _addError(innerError);
        throw innerError;
      }).then((_) {
        // If there are no errors in the onException queue, re-throw the
        // original error that caused it to run.
        throw e;
      });
    }).whenComplete(() {
      return onComplete._run().catchError((e) {
        // If an error occurs in a task in the onComplete queue, make sure it's
        // registered in the error list and re-throw it.
        _addError(e);
        throw e;
      });
    }).whenComplete(() {
      if (_timeoutTimer != null) _timeoutTimer.cancel();
      _state = ScheduleState.DONE;
    });
  }

  /// Stop the current [TaskQueue] after the current task and any out-of-band
  /// tasks stop executing. If this is called before [this] has started running,
  /// no tasks in the [tasks] queue will be run.
  ///
  /// This won't cause an error, but any errors that are otherwise signaled will
  /// still cause the test to fail.
  void abort() {
    if (_state == ScheduleState.DONE) {
      throw new StateError("Called abort() after the schedule has finished "
          "running.");
    }

    currentQueue._abort();
  }

  /// Signals that an out-of-band error has occurred. Using [wrapAsync] along
  /// with `throw` is usually preferable to calling this directly.
  ///
  /// The metadata in [ScheduleError]s will be preserved.
  void signalError(error, [stackTrace]) {
    heartbeat();

    var scheduleError = new ScheduleError.from(this, error,
        stackTrace: stackTrace);
    if (_state == ScheduleState.DONE) {
      throw new StateError(
          "An out-of-band error was signaled outside of wrapAsync after the "
              "schedule finished running.\n"
          "${errorString()}");
    } else if (state == ScheduleState.SET_UP) {
      // If we're setting up, throwing the error will pipe it into the main
      // error-handling code.
      throw scheduleError;
    } else {
      _currentQueue._signalError(scheduleError);
    }
  }

  /// Adds [info] to the debugging output that will be printed if the test
  /// fails. Unlike [signalError], this won't cause the test to fail, nor will
  /// it short-circuit the current [TaskQueue]; it's just useful for providing
  /// additional information that may not fit cleanly into an existing error.
  void addDebugInfo(String info) => debugInfo.add(info);

  /// Notifies the schedule of an error that occurred in a task or out-of-band
  /// callback after the appropriate queue has timed out. If this schedule is
  /// still running, the error will be added to the errors list to be shown
  /// along with the timeout error; otherwise, a top-level error will be thrown.
  void _signalPostTimeoutError(error, [stackTrace]) {
    var scheduleError = new ScheduleError.from(this, error,
        stackTrace: stackTrace);
    _addError(scheduleError);
    if (_state == ScheduleState.DONE) {
      throw new StateError(
        "An out-of-band error was caught after the test timed out.\n"
        "${errorString()}");
    }
  }

  /// Returns a function wrapping [fn] that pipes any errors into the schedule
  /// chain. This will also block the current task queue from completing until
  /// the returned function has been called. It's used to ensure that
  /// out-of-band callbacks are properly handled by the scheduled test.
  ///
  /// [description] provides an optional description of the callback, which is
  /// used when generating error messages.
  ///
  /// The top-level `wrapAsync` function should usually be used in preference to
  /// this in test code.
  Function wrapAsync(fn(arg), [String description]) {
    if (_state == ScheduleState.DONE) {
      throw new StateError("wrapAsync called after the schedule has finished "
          "running.");
    }
    heartbeat();

    return currentQueue._wrapAsync(fn, description);
  }

  /// Like [wrapAsync], this ensures that the current task queue waits for
  /// out-of-band asynchronous code, and that errors raised in that code are
  /// handled correctly. However, [wrapFuture] wraps a [Future] chain rather
  /// than a single callback.
  ///
  /// The returned [Future] completes to the same value or error as [future].
  ///
  /// [description] provides an optional description of the future, which is
  /// used when generating error messages.
  ///
  /// The top-level `wrapFuture` function should usually be used in preference
  /// to this in test code.
  Future wrapFuture(Future future, [String description]) {
    var done = wrapAsync((fn) => fn(), description);

    future = future.then((result) => done(() => result)).catchError((e) {
      done(() {
        throw e;
      });
      // wrapAsync will catch the first throw, so we throw [e] again so it
      // propagates through the Future chain.
      throw e;
    });

    // Don't top-level the error, since it's already been signaled to the
    // schedule.
    future.catchError((_) => null);

    return future;
  }

  /// Returns a string representation of all errors registered on this schedule.
  String errorString() {
    if (errors.isEmpty) return "The schedule had no errors.";
    if (errors.length == 1 && debugInfo.isEmpty) return errors.first.toString();

    var border = "\n==========================================================="
      "=====================\n";
    var errorStrings = errors.map((e) => e.toString()).join(border);
    var message = "The schedule had ${errors.length} errors:\n$errorStrings";

    if (!debugInfo.isEmpty) {
      message = "$message$border\nDebug info:\n${debugInfo.join(border)}";
    }

    return message;
  }

  /// Notifies the schedule that progress is being made on an asynchronous task.
  /// This resets the timeout timer, and can be used in long-running tasks to
  /// keep them from timing out.
  void heartbeat() {
    if (_timeoutTimer != null) _timeoutTimer.cancel();
    if (_timeout == null) {
      _timeoutTimer = null;
    } else {
      _timeoutTimer = mock_clock.newTimer(_timeout, () {
        _timeoutTimer = null;
        currentQueue._signalTimeout(new ScheduleError.from(this, "The schedule "
            "timed out after $_timeout of inactivity."));
      });
    }
  }

  /// Register an error in the schedule's error list. This ensures that there
  /// are no duplicate errors, and that all errors are wrapped in
  /// [ScheduleError].
  void _addError(error) {
    if (error is ScheduleError && errors.contains(error)) return;
    errors.add(new ScheduleError.from(this, error));
  }
}

/// An enum of states for a [Schedule].
class ScheduleState {
  /// The schedule can have tasks added to its queue, but is not yet running
  /// them.
  static const SET_UP = const ScheduleState._("SET_UP");

  /// The schedule is actively running tasks. This includes running tasks in
  /// [Schedule.onException] and [Schedule.onComplete].
  static const RUNNING = const ScheduleState._("RUNNING");

  /// The schedule has finished running all its tasks, either successfully or
  /// with an error.
  static const DONE = const ScheduleState._("DONE");

  /// The name of the state.
  final String name;

  const ScheduleState._(this.name);

  String toString() => name;
}

/// A queue of asynchronous tasks to execute in order.
class TaskQueue {
  // TODO(nweiz): make this a read-only view when issue 8321 is fixed.
  /// The tasks in the queue.
  Iterable<Task> get contents => _contents;
  final _contents = new Queue<Task>();

  /// The name of the queue, for debugging purposes.
  final String name;

  /// If `true`, then new [Task]s in this queue will capture the current stack
  /// trace before running.
  bool get captureStackTraces => _schedule.captureStackTraces;

  /// The [Schedule] that created this queue.
  final Schedule _schedule;

  /// An out-of-band error signaled by [_schedule]. If this is non-null, it
  /// indicates that the queue should stop as soon as possible and re-throw this
  /// error.
  ScheduleError _error;

  /// The [SubstituteFuture] for the currently-running task in the queue, or
  /// null if no task is currently running.
  SubstituteFuture _taskFuture;

  /// The toal number of out-of-band callbacks that have been registered on
  /// [this].
  int _totalCallbacks = 0;

  /// Whether to stop running after the current task.
  bool _aborted = false;

  // TODO(nweiz): make this a read-only view when issue 8321 is fixed.
  /// The descriptions of all callbacks that are blocking the completion of
  /// [this].
  Iterable<String> get pendingCallbacks => _pendingCallbacks;
  final _pendingCallbacks = new Queue<String>();

  /// A completer that will be completed once [_pendingCallbacks] becomes empty
  /// after the queue finishes running its tasks.
  Future get _noPendingCallbacks => _noPendingCallbacksCompleter.future;
  final Completer _noPendingCallbacksCompleter = new Completer();

  /// A [Future] that completes when the tasks in [this] are all complete. If an
  /// error occurs while running this queue, the returned [Future] will complete
  /// with that error.
  ///
  /// The returned [Future] can complete before outstanding out-of-band
  /// callbacks have finished running.
  Future get onTasksComplete => _onTasksCompleteCompleter.future;
  final _onTasksCompleteCompleter = new Completer();

  TaskQueue._(this.name, this._schedule) {
    // Avoid top-leveling errors that are passed to onTasksComplete if there are
    // no listeners.
    onTasksComplete.catchError((_) {});
  }

  /// Whether this queue is currently running.
  bool get isRunning => _schedule.state == ScheduleState.RUNNING &&
      _schedule.currentQueue == this;

  /// Whether this queue is running its tasks (as opposed to waiting for
  /// out-of-band callbacks or not running at all).
  bool get isRunningTasks => isRunning && _schedule.currentTask != null;

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
  ///
  /// If this is called when this queue is currently running, it will run [fn]
  /// on the next event loop iteration rather than adding it to a queue--this is
  /// known as a "nested task". The current task will not complete until [fn]
  /// (and any [Future] it returns) has finished running. Any errors in [fn]
  /// will automatically be handled. Nested tasks run in parallel, unlike
  /// top-level tasks which run in sequence.
  Future schedule(fn(), [String description]) {
    if (isRunning) {
      var task = _schedule.currentTask;
      var wrappedFn = () => _schedule.wrapFuture(
          new Future.value().then((_) => fn()));
      if (task == null) return wrappedFn();
      return task.runChild(wrappedFn, description);
    }

    var task = new Task(() {
      return new Future.sync(fn).catchError((e) {
        throw new ScheduleError.from(_schedule, e);
      });
    }, description, this);
    _contents.add(task);
    return task.result;
  }

  /// Runs all the tasks in this queue in order.
  Future _run() {
    _schedule._currentQueue = this;
    _schedule.heartbeat();
    return Future.forEach(_contents, (task) {
      _schedule._currentTask = task;
      if (_error != null) throw _error;
      if (_aborted) return;

      _taskFuture = new SubstituteFuture(task.fn());
      return _taskFuture.whenComplete(() {
        _taskFuture = null;
        _schedule.heartbeat();
      }).catchError((e) {
        var error = new ScheduleError.from(_schedule, e);
        _signalError(error);
        throw _error;
      });
    }).whenComplete(() {
      _schedule._currentTask = null;
    }).then((_) {
      _onTasksCompleteCompleter.complete();
    }).catchError((e) {
      _onTasksCompleteCompleter.completeError(e);
      throw e;
    }).whenComplete(() {
      if (pendingCallbacks.isEmpty) return;
      return _noPendingCallbacks.catchError((e) {
        // Signal the error rather than passing it through directly so that if a
        // timeout happens after an in-task error, both are reported.
        _signalError(new ScheduleError.from(_schedule, e));
      });
    }).whenComplete(() {
      _schedule.heartbeat();
      // If the tasks were otherwise successful, make sure we throw any
      // out-of-band errors. If a task failed, make sure we throw the most
      // recent error.
      if (_error != null) throw _error;
    });
  }

  /// Stops this queue after the current task and any out-of-band callbacks
  /// finish running.
  void _abort() {
    assert(_schedule.state == ScheduleState.SET_UP || isRunning);
    _aborted = true;
  }

  /// Returns a function wrapping [fn] that pipes any errors into the schedule
  /// chain. This will also block [this] from completing until the returned
  /// function has been called. It's used to ensure that out-of-band callbacks
  /// are properly handled by the scheduled test.
  Function _wrapAsync(fn(arg), String description) {
    assert(_schedule.state == ScheduleState.SET_UP || isRunning);

    // It's possible that the queue timed out before [fn] finished.
    bool _timedOut() =>
      _schedule.currentQueue != this || pendingCallbacks.isEmpty;

    if (description == null) {
      description = "Out-of-band operation #${_totalCallbacks}";
    }

    if (captureStackTraces) {
      var stackString = prefixLines(terseTraceString(new Trace.current()));
      description += "\n\nStack trace:\n$stackString";
    }

    _totalCallbacks++;

    _pendingCallbacks.add(description);
    return (arg) {
      try {
        return fn(arg);
      } catch (e, stackTrace) {
        var error = new ScheduleError.from(
            _schedule, e, stackTrace: stackTrace);
        if (_timedOut()) {
          _schedule._signalPostTimeoutError(error);
        } else {
          _schedule.signalError(error);
        }
      } finally {
        if (_timedOut()) return;

        _pendingCallbacks.remove(description);
        if (_pendingCallbacks.isEmpty && !isRunningTasks) {
          _noPendingCallbacksCompleter.complete();
        }
      }
    };
  }

  /// Signals that an out-of-band error has been detected and the queue should
  /// stop running as soon as possible.
  void _signalError(ScheduleError error) {
    // If multiple errors are detected while a task is running, make sure the
    // earlier ones are recorded in the schedule.
    if (_error != null) _schedule._addError(_error);
    _error = error;
  }

  /// Notifies the queue that it has timed out and it needs to terminate
  /// immediately with a timeout error.
  void _signalTimeout(ScheduleError error) {
    _pendingCallbacks.clear();
    if (!isRunningTasks) {
      _noPendingCallbacksCompleter.completeError(error);
    } else if (_taskFuture != null) {
      // Catch errors coming off the old task future, in case it completes after
      // timing out.
      _taskFuture.substitute(new Future.error(error)).catchError((e) {
        _schedule._signalPostTimeoutError(e);
      });
    } else {
      // This branch probably won't be reached, but it's conceivable that the
      // event loop might get pumped when _taskFuture is null but we haven't yet
      // finished running all the tasks.
      _signalError(error);
    }
  }

  String toString() => name;

  /// Returns a detailed representation of the queue as a tree of tasks. If
  /// [highlight] is passed, that task is specially highlighted.
  ///
  /// [highlight] must be a task in this queue.
  String generateTree([Task highlight]) {
    assert(highlight == null || highlight.queue == this);
    return _contents.map((task) {
      var taskString = task == highlight
          ? task.toStringWithStackTrace()
          : task.toString();
      taskString = prefixLines(taskString,
          firstPrefix: task == highlight ? "> " : "* ");

      if (task == highlight && !task.children.isEmpty) {
        var childrenString = task.children.map((child) {
          var prefix = ">";
          if (child.state == TaskState.ERROR) {
            prefix = "X";
          } else if (child.state == TaskState.SUCCESS) {
            prefix = "*";
          }

          var childString = prefix == "*"
              ? child.toString()
              : child.toStringWithStackTrace();
          return prefixLines(childString,
              firstPrefix: "  $prefix ", prefix: "  | ");
        }).join('\n');
        taskString = '$taskString\n$childrenString';
      }

      return taskString;
    }).join("\n");
  }
}
