// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

part 'wrong_part_of_part.dart';

//   ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.PART_OF_DIFFERENT_LIBRARY
// [cfe] Using 'tests/language/part/enhanced_parts/wrong_part_of_part.dart' as part of 'tests/language/part/enhanced_parts/wrong_part_of_error_test.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/wrong_part_of_other_lib.dart'.

void main() {}
