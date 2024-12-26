// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'ffi_test_helpers.dart';

main() {
  // Ensure we have FfiTrampolineData in heap.
  final malloc =
      DynamicLibrary.process()
          .lookup<NativeFunction<Pointer<Void> Function(IntPtr)>>("malloc")
          .asFunction<Pointer<Void> Function(int)>();
  print(malloc);

  triggerGc();

  final pointer = malloc(100);

  print(pointer.address);

  final free = DynamicLibrary.process()
      .lookupFunction<Void Function(Pointer), void Function(Pointer)>('free');
  free(pointer);
}
