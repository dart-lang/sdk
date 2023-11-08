// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is used for testing asynchronous tests.
/// If a test is asynchronous, it needs to notify the testing driver
/// about this (otherwise tests may get reported as passing after main()
/// finished even if the asynchronous operations fail).
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
/// After every asyncStart() called is matched with a corresponding
/// asyncEnd() or asyncSuccess(_) call, the testing driver will be notified that
/// the tests is done.
library async_helper;

import 'dart:async';

import 'package:expect/expect.dart';

bool _initialized = false;
int _asyncLevel = 0;

Exception _buildException(String msg) {
  return Exception('Fatal: $msg. This is most likely a bug in your test.');
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

/// Call this after an asynchronous test has ended successfully. This is a helper
/// for calling [asyncEnd].
///
/// This method intentionally has a signature that matches `Future.then` as a
/// convenience for calling [asyncEnd] when a `Future` completes without error,
/// like this:
/// ```dart
/// asyncStart();
/// Future result = test();
/// result.then(asyncSuccess);
/// ```
void asyncSuccess(void _) {
  asyncEnd();
}

/// Helper method for performing asynchronous tests involving `Future`.
///
/// The function [test] must return a `Future` which completes without error
/// when the test is successful.
Future<void> asyncTest(Function() test) {
  asyncStart();
  return test().then(asyncSuccess);
}

/// Verifies that the asynchronous [result] throws a [T].
///
/// Fails if [result] completes with a value, or it completes with
/// an error which is not a [T].
///
/// Returns the accepted thrown object.
/// For example, to check the content of the thrown object,
/// you could write this:
/// ```
/// var e = await asyncExpectThrows<MyException>(asyncExpression)
/// Expect.isTrue(e.myMessage.contains("WARNING"));
/// ```
/// If `result` completes with an [ExpectException] error from another
/// failed test expectation, that error cannot be caught and accepted.
Future<T> asyncExpectThrows<T extends Object>(Future<void> result,
    [String reason = ""]) {
  // Delay computing the header text until the test has failed.
  // The header computation uses complicated language features,
  // and language tests should avoid doing complicated things
  // until after the actual test has had a chance to succeed.
  String header() {
    // Handle null being passed in from legacy code
    // while also avoiding producing an unnecessary null check warning here.
    if ((reason as dynamic) == null) reason = "";
    // Only include the type in the message if it's not `Object`.
    var type = Object() is! T ? "<$T>" : "";
    return "asyncExpectThrows$type($reason):";
  }

  // Unsound null-safety check.
  if ((result as dynamic) == null) {
    Expect.testError("${header()} result Future must not be null.");
  }

  // TODO(rnystrom): It might useful to validate that T is not bound to
  // ExpectException since that won't work.

  asyncStart();
  return result.then<T>((_) {
    throw ExpectException("${header()} Did not throw.");
  }, onError: (error, stack) {
    // A test failure doesn't count as throwing. Rethrow it.
    if (error is ExpectException) throw error;

    if (error is! T) {
      // Throws something unexpected.
      throw ExpectException(
          "${header()} Unexpected '${Error.safeToString(error)}'\n$stack");
    }

    asyncEnd();
    return error;
  });
}
