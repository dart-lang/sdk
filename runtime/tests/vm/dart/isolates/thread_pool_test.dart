// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions
// VMOptions=--disable_heap_verification --no_check_function_fingerprints

import 'dart:async';
import 'dart:ffi';

import 'package:expect/expect.dart';

import 'test_utils.dart';
import '../../../../../tests/ffi/dylib_utils.dart';

// This should be larger than max-new-space-size/tlab-size.
const int threadCount = 200;

final class Isolate extends Opaque {}

typedef Dart_CurrentIsolateFT = Pointer<Isolate> Function();
typedef Dart_CurrentIsolateNFT = Pointer<Isolate> Function();
typedef Dart_EnterIsolateFT = void Function(Pointer<Isolate>);
typedef Dart_EnterIsolateNFT = Void Function(Pointer<Isolate>);
typedef Dart_ExitIsolateFT = void Function();
typedef Dart_ExitIsolateNFT = Void Function();

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final threadPoolBarrierSync = ffiTestFunctions
    .lookupFunction<
      Void Function(
        Pointer<NativeFunction<Dart_CurrentIsolateNFT>>,
        Pointer<NativeFunction<Dart_EnterIsolateNFT>>,
        Pointer<NativeFunction<Dart_ExitIsolateNFT>>,
        IntPtr,
        Bool,
      ),
      void Function(
        Pointer<NativeFunction<Dart_CurrentIsolateNFT>>,
        Pointer<NativeFunction<Dart_EnterIsolateNFT>>,
        Pointer<NativeFunction<Dart_ExitIsolateNFT>>,
        int,
        bool,
      )
    >('ThreadPoolTest_BarrierSync');

final Pointer<NativeFunction<Dart_CurrentIsolateNFT>> dartCurrentIsolate =
    DynamicLibrary.executable().lookup("Dart_CurrentIsolate").cast();
final Pointer<NativeFunction<Dart_EnterIsolateNFT>> dartEnterIsolate =
    DynamicLibrary.executable().lookup("Dart_EnterIsolate").cast();
final Pointer<NativeFunction<Dart_ExitIsolateNFT>> dartExitIsolate =
    DynamicLibrary.executable().lookup("Dart_ExitIsolate").cast();

class Worker extends RingElement {
  final int id;
  Worker(this.id);

  Future run(dynamic _, dynamic _2) async {
    const bool exitAndReenterIsolate = true;
    threadPoolBarrierSync(
      dartCurrentIsolate,
      dartEnterIsolate,
      dartExitIsolate,
      threadCount,
      exitAndReenterIsolate,
    );
    return id;
  }
}

main(args) async {
  final ring = await Ring.create(threadCount);

  // Let each worker:
  //   - call into C
  //   - exit the isolate
  //   - wait until notified
  //   - continue & exit
  final results = await ring.run((int id) => Worker(id));

  Expect.equals(threadCount, results.length);
  for (int i = 0; i < threadCount; ++i) {
    Expect.equals(i, results[i]);
  }

  await ring.close();
}
