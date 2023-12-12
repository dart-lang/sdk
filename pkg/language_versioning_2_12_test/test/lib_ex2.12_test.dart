// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

// Explicit version.
// @dart=2.12

part "src/part_of_ex2.12_v_ex2.12.dart";

// Specification requires the part file to have
// the same explicit language version marker
// as the including library,
// not just the same language version.
part "src/part_of_ex2.12_v_im2.12.dart";
//   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE
// [cfe] The language version override has to be the same in the library and its part(s).

part "src/part_of_ex2.12_v_ex2.13.dart";
//   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE
// [cfe] The language version override has to be the same in the library and its part(s).

main() {
  print(x212x212);
}
