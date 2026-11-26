// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// A 'part of' with a library name is an error with enhanced parts, also
// when the including library has no name.

part 'part_of_name_unnamed_library_part.dart';
//   ^
// [cfe] Using 'tests/language/part/enhanced_parts/part_of_name_unnamed_library_part.dart' as part of 'tests/language/part/enhanced_parts/part_of_name_unnamed_library_error_test.dart' but its 'part of' declaration says 'my.lib'.

void main() {}
