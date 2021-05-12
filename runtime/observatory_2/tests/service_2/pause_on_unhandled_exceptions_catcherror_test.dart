// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression: https://github.com/dart-lang/sdk/issues/37953

import 'test_helper.dart';
import 'service_test_common.dart';

Future<void> throwAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
  throw 'Throw from throwAsync!';
}

Future<void> nestedThrowAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
  await throwAsync();
}

testeeMain() async {
  await throwAsync().then((v) {
    print('Hello from then()!');
  }).catchError((e, st) {
    print('Caught in catchError: $e!');
  });
  // Make sure we can chain through off-stack awaiters as well.
  try {
    await nestedThrowAsync();
  } catch (e) {
    print('Caught in catch: $e!');
  }
}

var tests = <IsolateTest>[
  // We shouldn't get any debugger breaks before exit as all exceptions are
  // caught (via `Future.catchError()`).
  hasStoppedAtExit,
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true,
    pause_on_exit: true,
    testeeConcurrent: testeeMain,
    extraArgs: extraDebuggingArgs);
