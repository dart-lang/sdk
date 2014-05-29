// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(nweiz): Add support for calling [schedule] while the schedule is already
// running.
// TODO(nweiz): Port the non-Pub-specific scheduled test libraries from Pub.
library scheduled_test;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart' as unittest;

import 'src/schedule.dart';
import 'src/schedule_error.dart';

export 'package:unittest/unittest.dart' hide
    test, solo_test, group, setUp, tearDown, completes, completion;

export 'src/schedule.dart';
export 'src/schedule_error.dart';
export 'src/scheduled_future_matchers.dart';
export 'src/task.dart';

/// The [Schedule] for the current test. This is used to add new tasks and
/// inspect the state of the schedule.
///
/// This is `null` when there's no test currently running.
Schedule get currentSchedule => _currentSchedule;
Schedule _currentSchedule;

/// The user-provided setUp function. This is set for each test during
/// `unittest.setUp`.
Function _setUpFn;

/// Creates a new test case with the given description and body.
///
/// This has the same semantics as [unittest.test].
///
/// If [body] returns a [Future], that future will automatically be wrapped with
/// [wrapFuture].
void test(String description, body()) =>
  _test(description, body, unittest.test);

/// Creates a new test case with the given description and body that will be the
/// only test run in this file.
///
/// This has the same semantics as [unittest.solo_test].
///
/// If [body] returns a [Future], that future will automatically be wrapped with
/// [wrapFuture].
void solo_test(String description, body()) =>
  _test(description, body, unittest.solo_test);

void _test(String description, body(), Function testFn) {
  maybeWrapFuture(future, description) {
    if (future != null) wrapFuture(future, description);
  }

  unittest.ensureInitialized();
  _ensureSetUpForTopLevel();
  testFn(description, () {
    var completer = new Completer();

    // Capture this in a local variable in case we capture an out-of-band error
    // after the schedule completes.
    var errorHandler;

    Chain.capture(() {
      _currentSchedule = new Schedule();
      errorHandler = _currentSchedule.signalError;
      return currentSchedule.run(() {
        if (_setUpFn != null) maybeWrapFuture(_setUpFn(), "set up");
        maybeWrapFuture(body(), "test body");
      }).catchError((error, stackTrace) {
        if (error is ScheduleError) {
          assert(error.schedule.errors.contains(error));
          assert(error.schedule == currentSchedule);
          unittest.registerException(error.schedule.errorString());
        } else {
          unittest.registerException(error, new Chain.forTrace(stackTrace));
        }
      }).then(completer.complete);
    }, onError: (error, stackTrace) => errorHandler(error, stackTrace));

    return completer.future;
  });
}

/// Whether or not the tests currently being defined are in a group. This is
/// only true when defining tests, not when executing them.
bool _inGroup = false;

/// Creates a new named group of tests. This has the same semantics as
/// [unittest.group].
void group(String description, void body()) {
  unittest.ensureInitialized();
  _ensureSetUpForTopLevel();
  unittest.group(description, () {
    var wasInGroup = _inGroup;
    _inGroup = true;
    body();
    _inGroup = wasInGroup;
  });
}

/// Schedules a task, [fn], to run asynchronously as part of the main task queue
/// of [currentSchedule]. Tasks will be run in the order they're scheduled. If
/// [fn] returns a [Future], tasks after it won't be run until that [Future]
/// completes.
///
/// The return value will be completed once the scheduled task has finished
/// running. Its return value is the same as the return value of [fn], or the
/// value it completes to if it's a [Future].
///
/// If [description] is passed, it's used to describe the task for debugging
/// purposes when an error occurs.
///
/// If this is called when a task queue is currently running, it will run [fn]
/// on the next event loop iteration rather than adding it to a queue. The
/// current task will not complete until [fn] (and any [Future] it returns) has
/// finished running. Any errors in [fn] will automatically be handled.
Future schedule(fn(), [String description]) =>
  currentSchedule.tasks.schedule(fn, description);

/// Register a [setUp] function for a test [group]. This has the same semantics
/// as [unittest.setUp]. Tasks may be scheduled using [schedule] within
/// [setUpFn], and [currentSchedule] may be accessed as well.
///
/// Note that there is no associated [tearDown] function. Instead, tasks should
/// be scheduled for [currentSchedule.onComplete] or
/// [currentSchedule.onException]. These tasks will be run after each test's
/// schedule is completed.
void setUp(setUpFn()) {
  _setUpScheduledTest(setUpFn);
}

/// Whether [unittest.setUp] has been called in the top level scope.
bool _setUpForTopLevel = false;

/// If we're in the top-level scope (that is, not in any [group]s) and
/// [unittest.setUp] hasn't been called yet, call it.
void _ensureSetUpForTopLevel() {
  if (_inGroup || _setUpForTopLevel) return;
  _setUpScheduledTest();
}

/// Registers callbacks for [unittest.setUp] and [unittest.tearDown] that set up
/// and tear down the scheduled test infrastructure.
void _setUpScheduledTest([void setUpFn()]) {
  if (!_inGroup) {
    _setUpForTopLevel = true;
    var oldWrapAsync = unittest.wrapAsync;
    unittest.setUp(() {
      if (currentSchedule != null) {
        throw new StateError('There seems to be another scheduled test '
            'still running.');
      }

      unittest.wrapAsync = (f, [description]) {
        // It's possible that this setup is run before a vanilla unittest test
        // if [unittest.test] is run in the same context as
        // [scheduled_test.test]. In that case, [currentSchedule] will never be
        // set and we should forward to the [unittest.wrapAsync].
        if (currentSchedule == null) return oldWrapAsync(f, description);
        return currentSchedule.wrapAsync(f, description);
      };

      if (_setUpFn != null) {
        var parentFn = _setUpFn;
        _setUpFn = () { parentFn(); setUpFn(); };
      } else {
        _setUpFn = setUpFn;
      }
    });

    unittest.tearDown(() {
      unittest.wrapAsync = oldWrapAsync;
      _currentSchedule = null;
      _setUpFn = null;
    });
  } else {
    unittest.setUp(() {
      if (_setUpFn != null) {
        var parentFn = _setUpFn;
        _setUpFn = () { parentFn(); setUpFn(); };
      } else {
        _setUpFn = setUpFn;
      }
    });
  }
}

/// Like [wrapAsync], this ensures that the current task queue waits for
/// out-of-band asynchronous code, and that errors raised in that code are
/// handled correctly. However, [wrapFuture] wraps a [Future] chain rather than
/// a single callback.
///
/// The returned [Future] completes to the same value or error as [future].
///
/// [description] provides an optional description of the future, which is
/// used when generating error messages.
Future wrapFuture(Future future, [String description]) {
  if (currentSchedule == null) {
    throw new StateError("Unexpected call to wrapFuture with no current "
        "schedule.");
  }

  return currentSchedule.wrapFuture(future, description);
}
