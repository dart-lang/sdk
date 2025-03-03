// Copyright (c) 2021, the Dart project authors.
// Please see the AUTHORS file for details. 
// All rights reserved. Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// SharedObjects=ffi_test_functions

import 'dart:ffi';

// Correcting ABI-specific mappings by covering all common ABIs.
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int32(),
  Abi.androidX64: Int64(),
  Abi.fuchsiaArm64: Int8(), // Originally defined
  Abi.iosArm: Int32(),
  Abi.iosArm64: Int64(),
  Abi.linuxArm: Int32(),
  Abi.linuxArm64: Int64(),
  Abi.linuxIA32: Int32(),
  Abi.linuxX64: Int64(),
  Abi.macosArm64: Int64(),
  Abi.macosX64: Int64(),
  Abi.windowsIA32: Int32(),
  Abi.windowsX64: Int64(),
})
final class Complete extends AbiSpecificInteger {
  const Complete();
}

void main() {
  // Now it works without a compile-time error
  final ptr = nullptr.cast<Complete>();
  print(ptr);
}
