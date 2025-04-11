// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:isolate';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final initializeApi = ffiTestFunctions
    .lookupFunction<
      IntPtr Function(Pointer<Void>),
      int Function(Pointer<Void>)
    >("InitDartApiDL");
final enterBarrier = ffiTestFunctions
    .lookupFunction<Void Function(IntPtr, Bool), void Function(int, bool)>(
      "WaitUntilNThreadsEnterBarrier",
    );

main() async {
  initializeApi(NativeApi.initializeApiDLData);

  const threadBarrierCount = 30;

  // The threads may explicitly decrease the mutator count by using
  //   * Dart_ExitIsolate()
  //   * block and
  //   * Dart_EnterIsolate()
  await testNativeBarrier(threadBarrierCount, true);

  // The threads may not explicitly exit the isolate but the VM may implicitly
  // (when entering an isolate for execution) kick other threads out of the
  // mutator count (by making them implicitly go to slow path when trying to
  // leave a safepoint).
  await testNativeBarrier(threadBarrierCount, false);
}

Future testNativeBarrier(int count, bool exitAndReenterIsolate) async {
  final all = <Future>[];
  for (int i = 0; i < count; ++i) {
    all.add(Isolate.run(() => enterBarrier(count, true)));
  }
  await Future.wait(all);
}
