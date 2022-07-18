// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

// Explicit version.
// @dart=2.8

part "src/part_of_ex2.8_v_ex2.8.dart";

part "src/part_of_ex2.8_v_ex2.7.dart";
//   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE
// [cfe] The language version override has to be the same in the library and its part(s).

part "src/part_of_ex2.8_v_im2.7.dart";
//   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE
// [cfe] The language version override has to be the same in the library and its part(s).

void main() {
  print(x28x28);
}
