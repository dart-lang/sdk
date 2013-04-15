// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library task;

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

import '../scheduled_test.dart' show currentSchedule;
import 'future_group.dart';
import 'schedule.dart';
import 'utils.dart';

typedef Future TaskBody();

/// A single task to be run as part of a [TaskQueue].
///
/// There are two levels of tasks. **Top-level tasks** are created by calling
/// [TaskQueue.schedule] before the queue in question is running. They're run in
/// sequence as part of that [TaskQueue]. **Nested tasks** are created by
/// calling [TaskQueue.schedule] once the queue is already running, and are run
/// in parallel as part of a top-level task.
class Task {
  /// The queue to which this [Task] belongs.
  final TaskQueue queue;

  // TODO(nweiz): make this a read-only view when issue 8321 is fixed.
  /// Child tasks that have been spawned while running this task. This will be
  /// empty if this task is a nested task.
  final children = new Queue<Task>();

  /// A [FutureGroup] that will complete once all current child tasks are
  /// finished running. This will be null if no child tasks are currently
  /// running.
  FutureGroup _childGroup;

  /// A description of this task. Used for debugging. May be `null`.
  final String description;

  /// The parent task, if this is a nested task that was started while another
  /// task was running. This will be `null` for top-level tasks.
  final Task parent;

  /// The body of the task.
  TaskBody fn;

  /// The current state of [this].
  TaskState get state => _state;
  var _state = TaskState.WAITING;

  /// The identifier of the task. For top-level tasks, this is the index of the
  /// task within [queue]; for nested tasks, this is the index within
  /// [parent.children]. It's used for debugging when [description] isn't
  /// provided.
  int _id;

  /// A Future that will complete to the return value of [fn] once this task
  /// finishes running.
  Future get result => _resultCompleter.future;
  final _resultCompleter = new Completer();

  final Trace stackTrace;

  Task(fn(), String description, TaskQueue queue)
    : this._(fn, description, queue, null, queue.contents.length);

  Task._child(fn(), String description, Task parent)
    : this._(fn, description, parent.queue, parent, parent.children.length);

  Task._(fn(), this.description, TaskQueue queue, this.parent, this._id)
      : queue = queue,
        stackTrace = queue.captureStackTraces ? new Trace.current() : null {
    this.fn = () {
      if (state != TaskState.WAITING) {
        throw new StateError("Can't run $state task '$this'.");
      }

      _state = TaskState.RUNNING;
      var future = new Future.value().then((_) => fn())
          .whenComplete(() {
        if (_childGroup == null || _childGroup.completed) return;
        return _childGroup.future;
      });
      chainToCompleter(future, _resultCompleter);
      return future;
    };

    // If the parent queue experiences an error before this task has started
    // running, pipe that error out through [result]. This ensures that we don't
    // get deadlocked by something like `expect(schedule(...), completes)`.
    queue.onTasksComplete.catchError((e) {
      if (state == TaskState.WAITING) _resultCompleter.completeError(e);
    });

    // catchError makes sure any error thrown by fn isn't top-leveled by virtue
    // of being passed to the result future.
    result.then((_) {
      _state = TaskState.SUCCESS;
    }).catchError((e) {
      _state = TaskState.ERROR;
      throw e;
    }).catchError((_) {});
  }

  /// Run [fn] as a child of this task. Returns a Future that will complete with
  /// the result of the child task. This task will not complete until [fn] has
  /// finished.
  Future runChild(fn(), String description) {
    var task = new Task._child(fn, description, this);
    children.add(task);
    if (_childGroup == null || _childGroup.completed) {
      _childGroup = new FutureGroup();
    }
    // Ignore errors in the FutureGroup; they'll get picked up via wrapFuture,
    // and we don't want them to short-circuit the other Futures.
    _childGroup.add(task.result.catchError((_) {}));
    task.fn();
    return task.result;
  }

  String toString() => description == null ? "#$_id" : description;

  String toStringWithStackTrace() {
    var result = toString();
    if (stackTrace != null) {
      var stackString = prefixLines(terseTraceString(stackTrace));
      result += "\n\nStack trace:\n$stackString";
    }
    return result;
  }

  /// Returns a detailed representation of [queue] with this task highlighted.
  String generateTree() => queue.generateTree(this);
}

/// An enum of states for a [Task].
class TaskState {
  /// The task is waiting to be run.
  static const WAITING = const TaskState._("WAITING");

  /// The task is currently running.
  static const RUNNING = const TaskState._("RUNNING");

  /// The task has finished running successfully.
  static const SUCCESS = const TaskState._("SUCCESS");

  /// The task has finished running with an error.
  static const ERROR = const TaskState._("ERROR");

  /// The name of the state.
  final String name;

  /// Whether the state indicates that the task has finished running. This is
  /// true for both the [SUCCESS] and [ERROR] states.
  bool get isDone => this == SUCCESS || this == ERROR;

  const TaskState._(this.name);

  String toString() => name;
}
