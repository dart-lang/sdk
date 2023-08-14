// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final initializeApi = ffiTestFunctions.lookupFunction<
    IntPtr Function(Pointer<Void>),
    int Function(Pointer<Void>)>("InitDartApiDL");
final enterBarrier =
    ffiTestFunctions.lookupFunction<Void Function(IntPtr), void Function(int)>(
        "WaitUntilNThreadsEnterBarrier");

main() async {
  const threadBarrierCount = 30;

  initializeApi(NativeApi.initializeApiDLData);

  final all = <Future>[];
  for (int i = 0; i < threadBarrierCount; ++i) {
    all.add(Isolate.run(() => enterBarrier(threadBarrierCount)));
  }
  await Future.wait(all);
}
