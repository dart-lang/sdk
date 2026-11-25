// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "self_part_part1.dart";
//      ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.PART_OF_NON_PART
// [cfe] A file can't be a part of itself.

part "self_part_part1.dart";
//   ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.PART_OF_NON_PART
// [cfe] A file can't be a part of itself.

main() {
  print('part should not be able to recursively include self as library part');
}
