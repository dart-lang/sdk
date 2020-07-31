// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is used for testing asynchronous tests.
/// If a test is asynchronous, it needs to notify the testing driver
/// about this (otherwise tests may get reported as passing [after main()
/// finished] even if the asynchronous operations fail).
///
/// This library provides four methods
///  - asyncStart(): Needs to be called before an asynchronous operation is
///                  scheduled.
///  - asyncEnd(): Needs to be called as soon as the asynchronous operation
///                ended.
///  - asyncSuccess(_): Variant of asyncEnd useful together with Future.then.
///  - asyncTest(f()): Helper method that wraps a computation that returns a
///                    Future with matching calls to asyncStart() and
///                    asyncSuccess(_).
/// After the last asyncStart() called was matched with a corresponding
/// asyncEnd() or asyncSuccess(_) call, the testing driver will be notified that
/// the tests is done.

library async_helper;

import 'dart:async';

import 'package:expect/expect.dart';

bool _initialized = false;
int _asyncLevel = 0;

Exception _buildException(String msg) {
  return new Exception('Fatal: $msg. This is most likely a bug in your test.');
}

/// Call this method before an asynchronous test is created.
///
/// If [count] is provided, expect [count] [asyncEnd] calls instead of just one.
void asyncStart([int count = 1]) {
  if (count <= 0) return;
  if (_initialized && _asyncLevel == 0) {
    throw _buildException('asyncStart() was called even though we are done '
        'with testing.');
  }
  if (!_initialized) {
    print('unittest-suite-wait-for-done');
    _initialized = true;
  }
  _asyncLevel += count;
}

/// Call this after an asynchronous test has ended successfully.
void asyncEnd() {
  if (_asyncLevel <= 0) {
    if (!_initialized) {
      throw _buildException('asyncEnd() was called before asyncStart().');
    } else {
      throw _buildException('asyncEnd() was called more often than '
          'asyncStart().');
    }
  }
  _asyncLevel--;
  if (_asyncLevel == 0) {
    print('unittest-suite-success');
  }
}

/**
 * Call this after an asynchronous test has ended successfully. This is a helper
 * for calling [asyncEnd].
 *
 * This method intentionally has a signature that matches [:Future.then:] as a
 * convenience for calling [asyncEnd] when a [:Future:] completes without error,
 * like this:
 *
 *     asyncStart();
 *     Future result = test();
 *     result.then(asyncSuccess);
 */
void asyncSuccess(_) => asyncEnd();

/**
 * Helper method for performing asynchronous tests involving [:Future:].
 *
 * [f] must return a [:Future:] for the test computation.
 */
Future<void> asyncTest(f()) {
  asyncStart();
  return f().then(asyncSuccess);
}

bool _pass(dynamic object) => true;

/// Calls [f] and verifies that it throws a `T`.
///
/// The optional [check] function can provide additional validation that the
/// correct object is being thrown. For example, to check the content of the
/// thrown object you could write this:
///
///     asyncExpectThrows<MyException>(myThrowingFunction,
///          (e) => e.myMessage.contains("WARNING"));
///
/// If `f` fails an expectation (i.e., throws an [ExpectException]), that
/// exception is not caught by [asyncExpectThrows]. The test is still considered
/// failing.
void asyncExpectThrows<T>(Future<void> f(),
    [bool check(T error) = _pass, String reason = ""]) {
  var type = "";
  if (T != dynamic && T != Object) type = "<$T>";
  // Handle null being passed in from legacy code while also avoiding producing
  // an unnecessary null check warning here.
  if ((reason as dynamic) == null) reason = "";
  var header = "asyncExpectThrows$type(${reason}):";

  // TODO(rnystrom): It might useful to validate that T is not bound to
  // ExpectException since that won't work.

  if (f is! Function()) {
    // Only throws from executing the function body should count as throwing.
    // The failure to even call `f` should throw outside the try/catch.
    Expect.testError("$header Function not callable with zero arguments.");
  }

  var result = f();
  if (result is! Future) {
    Expect.testError("$header Function did not return a Future.");
  }

  asyncStart();
  result.then<Null>((_) {
    throw ExpectException("$header Did not throw.");
  }).catchError((error, stack) {
    // A test failure doesn't count as throwing.
    if (error is ExpectException) throw error;

    if (error is! T || (check != null && !check(error))) {
      // Throws something unexpected.
      throw ExpectException(
          "$header Unexpected '${Error.safeToString(error)}'\n$stack");
    }

    asyncEnd();
  });
}
