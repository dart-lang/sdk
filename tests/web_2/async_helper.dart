// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library async_helper;

/**
 * Asynchronous test runner.
 *
 * [test] is a one argument function which must accept a one argument
 * function (onDone).  The test function may start asynchronous tasks,
 * and must call onDone exactly once when all asynchronous tasks have
 * completed.  The argument to onDone is a bool which indicates
 * success of the complete test.
 */
void asyncTest(void test(void onDone(bool success))) {
  onDone(bool success) {
    if (!success) throw 'test failed';
    print('unittest-suite-success');
  }

  test(onDone);
  print('unittest-suite-wait-for-done');
}
