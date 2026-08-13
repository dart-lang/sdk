// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/62716

import 'dart:ffi';
import 'dart:nativewrappers';

extension on int {
  @Native<Void Function(Pointer<Void>)>(symbol: 'x')
  // [error column 4]
  // [cfe] Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.
  external void x();
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER
}

extension on dynamic {
  @Native<Void Function(Pointer<Void>)>(symbol: 'z')
  external void z();
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER
  // [cfe] Expected type 'void Function(dynamic)' to be 'void Function(Pointer<Void>)', which is the Dart type corresponding to 'NativeFunction<Void Function(Pointer<Void>)>'.
}

extension on void Function() {
  @Native<Void Function(Pointer<Void>)>(symbol: 'f')
  external void f();
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER
  // [cfe] Expected type 'void Function(void Function())' to be 'void Function(Pointer<Void>)', which is the Dart type corresponding to 'NativeFunction<Void Function(Pointer<Void>)>'.

  @Native<Void Function(Handle)>(symbol: 'f2')
  external void f2();
}

extension on NativeFieldWrapperClass1 {
  @Native<Void Function(Pointer<Void>)>(symbol: 'y')
  external void y();
}

void main() {}
