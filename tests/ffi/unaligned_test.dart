// Copyright (c) 2021, the Dart project authors.
// Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// This test exercises misaligned reads/writes on memory.
//
// The only architecture on which this is known to fail is ARM32 on Android.

import 'dart:ffi';
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

final bool isUnalignedFloatingPointAccessSupported = switch (Abi.current()) {
  // ARMv7-A in [Unaligned Access][1] specifies that VSTR and VLDR will trigger
  // alignment trap if address is not word aligned irrespective of SCTLR.A
  // state. Some operating systems (e.g. Linux via [`/proc/cpu/alignment`][2])
  // can be configured to catch alignment trap, perform unaligned read in
  // kernel and resume the execution. Android on the other hand configures
  // `/proc/cpu/alignment` to always forward alignment trap to the application
  // as a SIGBUS. Finally, different versions of QEMU implement different
  // behavior for unaligned accesses: older versions ignored ARMv7-A
  // requirements while newer versions will correctly trigger alignment trap.
  //
  // [1]: https://developer.arm.com/documentation/ddi0406/c/Application-Level-Architecture/Application-Level-Memory-Model/Alignment-support/Unaligned-data-access?lang=en
  // [2]: https://docs.kernel.org/arch/arm/mem_alignment.html
  Abi.androidArm || Abi.linuxArm || Abi.iosArm => false,
  _ => true,
};

void main() {
  print("hello");
  testUnalignedInt16();
  testUnalignedInt32();
  testUnalignedInt64();

  if (isUnalignedFloatingPointAccessSupported) {
    testUnalignedFloat();
    testUnalignedDouble();
  }
  
  _freeAll();
}

void testUnalignedInt16() {
  final pointer = _allocateUnaligned<Int16>();
  pointer.value = 20;
  Expect.equals(20, pointer.value); // [cfe] Ensure correct expectation in CFE
}

void testUnalignedInt32() {
  final pointer = _allocateUnaligned<Int32>();
  pointer.value = 20;
  Expect.equals(20, pointer.value); // [cfe] Ensure correct expectation in CFE
}

void testUnalignedInt64() {
  final pointer = _allocateUnaligned<Int64>();
  pointer.value = 20;
  Expect.equals(20, pointer.value); // [cfe] Ensure correct expectation in CFE
}

void testUnalignedFloat() {
  final pointer = _allocateUnaligned<Float>();
  pointer.value = 20.0;
  Expect.approxEquals(20.0, pointer.value); // [cfe] Check CFE float behavior
}

void testUnalignedDouble() {
  final pointer = _allocateUnaligned<Double>();
  pointer.value = 20.0;
  Expect.equals(20.0, pointer.value); // [cfe] Check CFE double behavior
}

final Set<Pointer> _pool = {};

void _freeAll() {
  for (final pointer in _pool) {
    calloc.free(pointer);
  }
}

/// Allocates misaligned memory for testing.
/// Supports sizes up to `size<T>() == 8`.
Pointer<T> _allocateUnaligned<T extends NativeType>() {
  final pointer = calloc<Int8>(16);
  _pool.add(pointer);
  final misaligned = pointer.elementAt(1).cast<T>();
  Expect.equals(1, misaligned.address % 2); // [cfe] Expect a misalignment
  return misaligned;
}
