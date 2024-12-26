// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/59730: make
// sure that awaiter stack is correctly reconstructed for `FutureIterable`
// and `FutureRecordN` wait extensions.

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> throwAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
  throw 'Throw from throwAsync!';
}

Future<void> testeeMain() async {
  try {
    await [throwAsync()].wait;
  } catch (e) {
    // Ignore.
  }

  try {
    await (throwAsync(), throwAsync()).wait;
  } catch (e) {
    // Ignore.
  }

  await [throwAsync()].wait.catchError((e) {
    // Ignore.
    return [];
  });

  await (throwAsync(), throwAsync()).wait.catchError((e) {
    // Ignore.
    return (null, null);
  });
}

final tests = <IsolateTest>[
  // We shouldn't get any debugger breaks before exit as all exceptions are
  // caught.
  hasStoppedAtExit,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_unhandled_exceptions_future_extensions_test.dart',
      pauseOnUnhandledExceptions: true,
      pauseOnExit: true,
      testeeConcurrent: testeeMain,
    );
