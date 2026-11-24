// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of './non_tree_files//non_tree_part1.dart'; // Different from one part.

//      ^
// [analyzer] unspecified
// [cfe] Using 'tests/language/part/enhanced_parts/non_tree_part2.dart' as part of 'tests/language/part/enhanced_parts//non_tree_files/non_tree_part1.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/non_tree_files//non_tree_part1.dart'.

int x = 42;
