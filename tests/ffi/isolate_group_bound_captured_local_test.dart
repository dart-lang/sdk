// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that exception is thrown when captured variables doesn't have
// pragma('vm:shared') annotation.
//
// VMOptions=--experimental-shared-data

import 'dart:async';
import 'dart:ffi';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

typedef CallbackNativeType = Void Function(Int64, Int32);

Future<void> testCapturedLocalVarNoDecoration() async {
  // ignore: unused_local_variable
  int foo_result = 42;
  Expect.throws(() {
    // ignore: unused_local_variable
    final callback = NativeCallable<CallbackNativeType>.isolateGroupBound((
      int a,
      int b,
    ) {
      foo_result += (a * b);
    });
  }, (e) => e.toString().contains("variables can be captured"));
}

Future<void> testCapturedLocalVarPragmaVmShared() async {
  @pragma('vm:shared')
  // ignore: unused_local_variable
  int foo_result = 42;
  Expect.throws(() {
    final callback = NativeCallable<CallbackNativeType>.isolateGroupBound((
      int a,
      int b,
    ) {
      foo_result += (a * b);
    });
  }, (e) => e.toString().contains("Only final not-late variables can be"));
}

Future<void> testCapturedLocalVarFinal() async {
  final int foo_result = 42;
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound((
    int a,
    int b,
  ) {
    foo_result + (a * b);
  });
  callback.close();
}

main(args, message) async {
  asyncStart();
  await testCapturedLocalVarNoDecoration();
  await testCapturedLocalVarPragmaVmShared();
  await testCapturedLocalVarFinal();
  asyncEnd();
  print("All tests completed :)");
}
