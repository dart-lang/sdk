// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:isolate';
import 'dart:ffi';

import 'callback_tests_utils.dart';

typedef SimpleAdditionType = Int32 Function(Int32, Int32);
int simpleAddition(int x, int y) {
  print("simpleAddition($x, $y)");
  return x + y;
}

void main() async {
  // The main isolate is very special and cannot be suspended (due to having an
  // active api scope throughout it's lifetime), so we run this test in a helper
  // isolate.
  const int count = 50;
  final futures = <Future>[];
  for (int i = 0; i < count; ++i) {
    futures.add(
      Isolate.run(() async {
        // First make the callback pointer.
        final callbackFunctionPointer =
            Pointer.fromFunction<SimpleAdditionType>(simpleAddition, 0);

        // Then cause suspenion of [Thread].
        await Future.delayed(const Duration(seconds: 1));

        // Then make use of callback.
        CallbackTest("SimpleAddition", callbackFunctionPointer).run();
      }),
    );
  }
  await Future.wait(futures);
}
