// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(nweiz): Add support for calling [schedule] while the schedule is already
// running.
// TODO(nweiz): Port the non-Pub-specific scheduled test libraries from Pub.
/// A package for writing readable tests of asynchronous behavior.
///
/// ## Installing ##
///
/// Use [pub][] to install this package. Add the following to your
/// `pubspec.yaml` file.
///
///     dependencies:
///       scheduled_test: any
///
/// Then run `pub install`.
///
/// For more information, see the
/// [scheduled_test package on pub.dartlang.org][pkg].
///
/// This package works by building up a queue of asynchronous tasks called a
/// "schedule", then executing those tasks in order. This allows the tests to
/// read like synchronous, linear code, despite executing asynchronously.
///
/// The `scheduled_test` package is built on top of `unittest`, and should be
/// imported instead of `unittest`. It provides its own version of [group],
/// [test], and [setUp], and re-exports most other APIs from unittest.
///
/// To schedule a task, call the [schedule] function. For example:
///
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       test('writing to a file and reading it back should work', () {
///         schedule(() {
///           // The schedule won't proceed until the returned Future has
///           // completed.
///           return new File("output.txt").writeAsString("contents");
///         });
///
///         schedule(() {
///           return new File("output.txt").readAsString().then((contents) {
///             // The normal unittest matchers can still be used.
///             expect(contents, equals("contents"));
///           });
///         });
///       });
///     }
///
/// ## Setting up and tearing down
///
/// The `scheduled_test` package defines its own [setUp] method that works just
/// like the one in `unittest`. Tasks can be scheduled in [setUp]; they'll be
/// run before the tasks scheduled by tests in that group. [currentSchedule] is
/// also set in the [setUp] callback.
///
/// This package doesn't have an explicit `tearDown` method. Instead, the
/// [currentSchedule.onComplete] and [currentSchedule.onException] task queues
/// can have tasks scheduled during [setUp]. For example:
///
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       var tempDir;
///       setUp(() {
///         schedule(() {
///           return createTempDir().then((dir) {
///             tempDir = dir;
///           });
///         });
///
///         currentSchedule.onComplete.schedule(() => deleteDir(tempDir));
///       });
///
///       // ...
///     }
///
/// ## Passing values between tasks
///
/// It's often useful to use values computed in one task in other tasks that are
/// scheduled afterwards. There are two ways to do this. The most
/// straightforward is just to define a local variable and assign to it. For
/// example:
///
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       test('computeValue returns 12', () {
///         var value;
///
///         schedule(() {
///           return computeValue().then((computedValue) {
///             value = computedValue;
///           });
///         });
///
///         schedule(() => expect(value, equals(12)));
///       });
///     }
///
/// However, this doesn't scale well, especially when you start factoring out
/// calls to [schedule] into library methods. For that reason, [schedule]
/// returns a [Future] that will complete to the same value as the return
/// value of the task. For example:
///
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       test('computeValue returns 12', () {
///         var valueFuture = schedule(() => computeValue());
///         schedule(() {
///           valueFuture.then((value) => expect(value, equals(12)));
///         });
///       });
///     }
///
/// ## Out-of-Band Callbacks
///
/// Sometimes your tests will have callbacks that don't fit into the schedule.
/// It's important that errors in these callbacks are still registered, though,
/// and that [Schedule.onException] and [Schedule.onComplete] still run after
/// they finish. When using `unittest`, you wrap these callbacks with
/// `expectAsyncN`; when using `scheduled_test`, you use [wrapAsync] or
/// [wrapFuture].
///
/// [wrapAsync] has two important functions. First, any errors that occur in it
/// will be passed into the [Schedule] instead of causing the whole test to
/// crash. They can then be handled by [Schedule.onException] and
/// [Schedule.onComplete]. Second, a task queue isn't considered finished until
/// all of its [wrapAsync]-wrapped functions have been called. This ensures that
/// [Schedule.onException] and [Schedule.onComplete] will always run after all
/// the test code in the main queue.
///
/// Note that the [completes], [completion], and [throws] matchers use
/// [wrapAsync] internally, so they're safe to use in conjunction with scheduled
/// tests.
///
/// Here's an example of a test using [wrapAsync] to catch errors thrown in the
/// callback of a fictional `startServer` function:
///
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       test('sendRequest sends a request', () {
///         startServer(wrapAsync((request) {
///           expect(request.body, equals('payload'));
///           request.response.close();
///         }));
///
///         schedule(() => sendRequest('payload'));
///       });
///     }
///
/// [wrapFuture] works similarly to [wrapAsync], but instead of wrapping a
/// single callback it wraps a whole [Future] chain. Like [wrapAsync], it
/// ensures that the task queue doesn't complete until the out-of-band chain has
/// finished, and that any errors in the chain are piped back into the scheduled
/// test. For example:
///
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       test('sendRequest sends a request', () {
///         wrapFuture(server.nextRequest.then((request) {
///           expect(request.body, equals('payload'));
///           expect(request.headers['content-type'], equals('text/plain'));
///         }));
///
///         schedule(() => sendRequest('payload'));
///       });
///     }
///
/// ## Timeouts
///
/// `scheduled_test` has a built-in timeout of 5 seconds (configurable via
/// [Schedule.timeout]). This timeout is aware of the structure of the schedule;
/// this means that it will reset for each task in a queue, when moving between
/// queues, or almost any other sort of interaction with [currentSchedule]. As
/// long as the [Schedule] knows your test is making some sort of progress, it
/// won't time out.
///
/// If a single task might take a long time, you can also manually tell the
/// [Schedule] that it's making progress by calling [Schedule.heartbeat], which
/// will reset the timeout whenever it's called.
///
/// [pub]: http://pub.dartlang.org
/// [pkg]: http://pub.dartlang.org/packages/scheduled_test
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

/// Creates a new test case with the given description and body. This has the
/// same semantics as [unittest.test].
void test(String description, void body()) =>
  _test(description, body, unittest.test);

/// Creates a new test case with the given description and body that will be the
/// only test run in this file. This has the same semantics as
/// [unittest.solo_test].
void solo_test(String description, void body()) =>
  _test(description, body, unittest.solo_test);

void _test(String description, void body(), Function testFn) {
  unittest.ensureInitialized();
  _ensureSetUpForTopLevel();
  testFn(description, () {
    var completer = new Completer();

    Chain.capture(() {
      _currentSchedule = new Schedule();
      return currentSchedule.run(() {
        if (_setUpFn != null) _setUpFn();
        body();
      }).catchError((error, stackTrace) {
        if (error is ScheduleError) {
          assert(error.schedule.errors.contains(error));
          assert(error.schedule == currentSchedule);
          unittest.registerException(error.schedule.errorString());
        } else {
          unittest.registerException(error, new Chain.forTrace(stackTrace));
        }
      }).then(completer.complete);
    }, onError: (error, chain) => currentSchedule.signalError(error, chain));

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
void setUp(void setUpFn()) {
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
