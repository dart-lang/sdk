// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'part_of_ancestor_error_test.dart';

part 'part_of_ancestor_part2.dart';
//   ^
// [analyzer] unspecified
// [cfe] Using 'tests/language/part/enhanced_parts/part_of_ancestor_part2.dart' as part of 'tests/language/part/enhanced_parts/part_of_ancestor_part1.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/part_of_ancestor_error_test.dart'.
