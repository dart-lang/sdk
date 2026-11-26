// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// An export in a part file that is not a part of this library must not
// crash the compiler; the mismatched 'part of' is reported as usual.

part 'export_in_wrong_part_part.dart';
//   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.PART_OF_DIFFERENT_LIBRARY
// [cfe] Using 'tests/language/part/enhanced_parts/export_in_wrong_part_part.dart' as part of 'tests/language/part/enhanced_parts/export_in_wrong_part_error_test.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/export_in_wrong_part_other_lib.dart'.

void main() {}
