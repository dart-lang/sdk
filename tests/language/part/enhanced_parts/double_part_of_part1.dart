// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'double_part_of_error_test.dart';

// Part the same file twice in a part, not just a library.
part 'double_part_of_part2.dart';
part 'double_part_of_part2.dart';
//   ^
// [analyzer] unspecified
// [cfe] Can't use 'tests/language/part/enhanced_parts/double_part_of_part2.dart' as a part more than once.
