// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library schedule_error;

import 'dart:async';

import 'schedule.dart';
import 'task.dart';
import 'utils.dart';

/// A wrapper for errors that occur during a scheduled test.
class ScheduleError extends AsyncError {
  /// The schedule during which this error occurred.
  final Schedule schedule;

  /// The task that was running when this error occurred. This may be `null` if
  /// there was no such task.
  final Task task;

  /// The task queue that was running when this error occured. This may be
  /// `null` if there was no such queue.
  final TaskQueue queue;

  /// The state of the schedule at the time the error was detected.
  final ScheduleState _stateWhenDetected;

  /// Creates a new [ScheduleError] wrapping [error]. The metadata in
  /// [AsyncError]s and [ScheduleError]s will be preserved.
  factory ScheduleError.from(Schedule schedule, error, {stackTrace,
      AsyncError cause}) {
    if (error is ScheduleError) {
      if (schedule == null) schedule = error.schedule;
    }

    if (error is AsyncError) {
      // Overwrite the explicit stack trace, because it probably came from a
      // rethrow in the first place.
      stackTrace = error.stackTrace;
      if (cause == null) cause = error.cause;
      error = error.error;
    }

    return new ScheduleError(schedule, error, stackTrace, cause);
  }

  ScheduleError(Schedule schedule, error, stackTrace, AsyncError cause)
      : super.withCause(error, stackTrace, cause),
        this.schedule = schedule,
        this.task = schedule.currentTask,
        this.queue = schedule.currentQueue,
        this._stateWhenDetected = schedule.state;

  String toString() {
    var result = new StringBuffer();

    var errorString = error.toString();
    if (errorString.contains("\n")) {
      result.add('ScheduleError:\n');
      result.add(prefixLines(errorString.trim()));
      result.add("\n\n");
    } else {
      result.add('ScheduleError: "$errorString"\n');
    }

    result.add('Stack trace:\n');
    result.add(prefixLines(stackTrace.toString().trim()));
    result.add("\n\n");

    if (task != null) {
      result.add('Error detected during task in queue "$queue":\n');
      result.add(task.generateTree());
    } else if (_stateWhenDetected == ScheduleState.DONE) {
      result.add('Error detected after all tasks in the schedule had '
          'finished.');
    } else if (_stateWhenDetected == ScheduleState.RUNNING) {
      result.add('Error detected when waiting for out-of-band callbacks in '
          'queue "$queue".');
    } else { // _stateWhenDetected == ScheduleState.SET_UP
      result.add('Error detected before the schedule started running.');
    }

    return result.toString();
  }
}
