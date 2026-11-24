// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// Does not `part of` back to this file.
part "self_part_part1.dart";

//   ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] Using 'tests/language/part/enhanced_parts/self_part_part1.dart' as part of 'tests/language/part/enhanced_parts/self_part_error_test.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/self_part_part1.dart'.

main() {
  print('part should not be able to recursively include self as library part');
}
