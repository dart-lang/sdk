// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_catch_clause, empty_catches

import 'common/test_helper.dart';

class Foo {}

String doThrow() {
  throw 'TheException';
  // ignore: dead_code
  return 'end of doThrow';
}

Future<void> asyncThrower() async {
  // ignore: await_only_futures
  await 0; // force async gap
  doThrow();
}

Future<void> testeeMain() async {
  try {
    // This is a regression case for https://dartbug.com/53334:
    // we should recognize `then(..., onError: ...)` as a catch
    // all exception handler.
    await asyncThrower().then(
      (v) => v,
      onError: (e, st) {
        // Caught and ignored.
      },
    );

    await asyncThrower().onError((error, stackTrace) {
      // Caught and ignored.
    });

    try {
      await asyncThrower();
    } on String catch (e) {
      // Caught and ignored.
    }

    try {
      await asyncThrower();
    } catch (e) {
      // Caught and ignored.
    }

    // This does not catch the exception.
    try {
      await asyncThrower(); // LINE_A
    } on double catch (e) {}
  } on Foo catch (e) {}
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
