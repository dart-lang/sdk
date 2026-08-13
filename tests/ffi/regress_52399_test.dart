// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

main() {
  fine();
  fine2();
  repro52399();
}

const length = 8;

repro52399() {
  final memory = malloc(length).cast<Int8>();
  for (int i = 0; i < length; i++) {
    memory[i] = 0;
  }
  final typedList1 = memory.asTypedList(length);
  // MSAN unhappy when unoptimized, due to runtime entry.
  final readVal = typedList1[0];
  print(readVal);
  free(memory);
}

fine() {
  final memory = calloc(length, 1).cast<Int8>();
  final typedList1 = memory.asTypedList(length);
  final readVal = typedList1[0];
  print(readVal);
  free(memory);
}

fine2() {
  final memory = malloc(length).cast<Int8>();
  for (int i = 0; i < length; i++) {
    memory[i] = 0;
  }
  final readVal = memory[0]; // MSAN doesn't see this one, it's force-optimized.
  print(readVal);
  free(memory);
}

@Native<Pointer<Void> Function(IntPtr num, IntPtr size)>(isLeaf: true)
external Pointer<Void> calloc(int num, int size);

@Native<Pointer<Void> Function(IntPtr)>(isLeaf: true)
external Pointer<Void> malloc(int size);

@Native<Void Function(Pointer)>(isLeaf: true)
external void free(Pointer pointer);
