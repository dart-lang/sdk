// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

part 'two_parts_of_part.dart';

//   ^
// [cfe] Using 'tests/language/part/enhanced_parts/two_parts_of_part.dart' as part of 'tests/language/part/enhanced_parts/two_parts_of_error_test.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/two_parts_of_other_lib.dart'.

void main() {}
