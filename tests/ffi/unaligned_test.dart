// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tests exercises misaligned reads/writes on memory.
//
// The only architecture on which this is known to fail is arm32 on Android.

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
  // as a SIGBUS. Finally, different version of QEMU implement different
  // behavior for unaligned accesses: older versions ignored ARMv7-A
  // requirements while newer versions will correctly trigger alignment trap.
  //
  // We have decided in https://dartbug.com/45009 that we are not going to
  // support unaligned accesses in FFI in a special way (e.g. it is on user
  // to be aware of potential problems with unaligned accesses). Consequently
  // we simply ignore double and float unaligned tests in configurations
  // where they cause alignment traps (irrespective of whether OS will fixup
  // and hide the trap from the user or not).
  //
  // [1]: https://developer.arm.com/documentation/ddi0406/c/Application-Level-Architecture/Application-Level-Memory-Model/Alignment-support/Unaligned-data-access?lang=en
  // [2]: https://docs.kernel.org/arch/arm/mem_alignment.html
  Abi.androidArm || Abi.linuxArm || Abi.iosArm => false,
  _ => true,
};

void main() {
  print("hello");
  testUnalignedInt16(); //# 01: ok
  testUnalignedInt32(); //# 02: ok
  testUnalignedInt64(); //# 03: ok
  if (isUnalignedFloatingPointAccessSupported) {
    testUnalignedFloat(); //# 04: ok
    testUnalignedDouble(); //# 05: ok
  }
  _freeAll();
}

void testUnalignedInt16() {
  final pointer = _allocateUnaligned<Int16>();
  pointer.value = 20;
  Expect.equals(20, pointer.value);
}

void testUnalignedInt32() {
  final pointer = _allocateUnaligned<Int32>();
  pointer.value = 20;
  Expect.equals(20, pointer.value);
}

void testUnalignedInt64() {
  final pointer = _allocateUnaligned<Int64>();
  pointer.value = 20;
  Expect.equals(20, pointer.value);
}

void testUnalignedFloat() {
  final pointer = _allocateUnaligned<Float>();
  pointer.value = 20.0;
  Expect.approxEquals(20.0, pointer.value);
}

void testUnalignedDouble() {
  final pointer = _allocateUnaligned<Double>();
  pointer.value = 20.0;
  Expect.equals(20.0, pointer.value);
}

final Set<Pointer> _pool = {};

void _freeAll() {
  for (final pointer in _pool) {
    calloc.free(pointer);
  }
}

/// Up to `size<T>() == 8`.
Pointer<T> _allocateUnaligned<T extends NativeType>() {
  final pointer = calloc<Int8>(16);
  _pool.add(pointer);
  final misaligned = pointer.elementAt(1).cast<T>();
  Expect.equals(1, misaligned.address % 2);
  return misaligned;
}
