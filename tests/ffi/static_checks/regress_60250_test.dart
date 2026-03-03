// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart format off

import 'dart:ffi';

extension type NativeSendPort(int id) {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [cfe] Expected type 'bool Function(NativeSendPort, int)' to be 'bool Function(int, int)', which is the Dart type corresponding to 'NativeFunction<Bool Function(Int64, Int64)>'.
}

extension on int {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
}

extension type InvalidNativeSendPort._(double id) {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [cfe] Expected type 'bool Function(InvalidNativeSendPort, int)' to be 'bool Function(int, int)', which is the Dart type corresponding to 'NativeFunction<Bool Function(Int64, Int64)>'.
}

extension on double {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [cfe] Expected type 'bool Function(double, int)' to be 'bool Function(int, int)', which is the Dart type corresponding to 'NativeFunction<Bool Function(Int64, Int64)>'.
}

extension on int {
  @Native<Bool Function(Int64)>(symbol: 'x')
  // [error column 4]
  // [cfe] Unexpected number of Native annotation parameters. Expected 2 but has 1.
  external bool wrongArity(int message);
  //            ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS
}

void main() {}
