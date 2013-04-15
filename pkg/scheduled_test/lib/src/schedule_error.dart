// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library schedule_error;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'schedule.dart';
import 'task.dart';
import 'utils.dart';

/// A wrapper for errors that occur during a scheduled test.
class ScheduleError {
  /// The wrapped error.
  final error;

  /// The stack trace that was attached to the error. Can be `null`.
  final stackTrace;

  /// The schedule during which this error occurred.
  final Schedule schedule;

  /// The task that was running when this error occurred. This may be `null` if
  /// there was no such task.
  final Task task;

  /// The task queue that was running when this error occured. This may be
  /// `null` if there was no such queue.
  final TaskQueue queue;

  /// The descriptions of out-of-band callbacks that were pending when this
  /// error occurred.
  final Iterable<String> pendingCallbacks;

  /// The state of the schedule at the time the error was detected.
  final ScheduleState _stateWhenDetected;

  int get hashCode => schedule.hashCode ^ task.hashCode ^ queue.hashCode ^
      _stateWhenDetected.hashCode ^ error.hashCode ^ stackTrace.hashCode;

  /// Creates a new [ScheduleError] wrapping [error]. The metadata in
  /// [ScheduleError]s will be preserved.
  factory ScheduleError.from(Schedule schedule, error,
                             {StackTrace stackTrace}) {
    if (error is ScheduleError) return error;

    var attachedTrace = getAttachedStackTrace(error);
    if (attachedTrace != null) {
      // Overwrite the explicit stack trace, because it probably came from a
      // rethrow in the first place.
      stackTrace = attachedTrace;
    }

    if (schedule.captureStackTraces && stackTrace == null) {
      stackTrace = new Trace.current();
    }

    return new ScheduleError(schedule, error, stackTrace);
  }

  // TODO(floitsch): restore StackTrace type when it has been integrated into
  // the core libraries.
  ScheduleError(Schedule schedule, error, var stackTrace)
      : error = error,
        stackTrace = stackTrace,
        schedule = schedule,
        task = schedule.currentTask,
        queue = schedule.currentQueue,
        pendingCallbacks = schedule.currentQueue == null ? <String>[]
            : schedule.currentQueue.pendingCallbacks.toList(),
        _stateWhenDetected = schedule.state;

  bool operator ==(other) => other is ScheduleError && task == other.task &&
      queue == other.queue && _stateWhenDetected == other._stateWhenDetected &&
      error == other.error && stackTrace == other.stackTrace;

  String toString() {
    var result = new StringBuffer();

    var errorString = error.toString();
    if (errorString.contains("\n")) {
      result.write('ScheduleError:\n');
      result.write(prefixLines(errorString.trim()));
      result.write("\n\n");
    } else {
      result.write('ScheduleError: "$errorString"\n');
    }

    if (stackTrace != null) {
      result.write('Stack trace:\n');
      result.write(prefixLines(terseTraceString(stackTrace)));
      result.write("\n\n");
    }

    if (task != null) {
      result.write('Error detected during task in queue "$queue":\n');
      result.write(task.generateTree());
    } else if (_stateWhenDetected == ScheduleState.DONE) {
      result.write('Error detected after all tasks in the schedule had '
          'finished.');
    } else if (_stateWhenDetected == ScheduleState.RUNNING) {
      result.write('Error detected when waiting for out-of-band callbacks in '
          'queue "$queue".');
    } else { // _stateWhenDetected == ScheduleState.SET_UP
      result.write('Error detected before the schedule started running.');
    }

    if (!pendingCallbacks.isEmpty) {
      result.write("\n\n");
      result.writeln("Pending out-of-band callbacks:");
      for (var callback in pendingCallbacks) {
        result.writeln(prefixLines(callback, firstPrefix: "* "));
      }
    }

    return result.toString().trim();
  }
}
