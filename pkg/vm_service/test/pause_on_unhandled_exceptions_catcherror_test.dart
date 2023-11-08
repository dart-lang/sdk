// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression: https://github.com/dart-lang/sdk/issues/37953

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

Future<void> throwAsync() async {
  await Future.delayed(const Duration(milliseconds: 10));
  throw 'Throw from throwAsync!';
}

Future<void> nestedThrowAsync() async {
  await Future.delayed(const Duration(milliseconds: 10));
  await throwAsync();
}

Future<void> testeeMain() async {
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

final tests = <IsolateTest>[
  // We shouldn't get any debugger breaks before exit as all exceptions are
  // caught (via `Future.catchError()`).
  hasStoppedAtExit,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_unhandled_exceptions_catcherror_test.dart',
      pause_on_unhandled_exceptions: true,
      pause_on_exit: true,
      testeeConcurrent: testeeMain,
    );
