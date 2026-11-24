// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Should be valid for both `part` directives of ../non_tree_error_test.dart`,
// since they refer to this file using `./non_tree_files//non_tree_part1.dart`
// and `.//non_tree_files/non_tree_part1.dart`.
// As URIs, those both have two directories to move past.
// (This assumes that a file system path treats `//` the same as `/`,
// and reads the same file.)
part of '../../non_tree_error_test.dart';

// Valid path for both `part` directive includes in ../non_tree_error_test.dart`
// which include this file.
// That makes it a part that is included by *two* files of the same library.
// It does not point back to both in its `part of`, only one.
part '../../non_tree_part2.dart'; // Does not point back .
//   ^
// [analyzer] unspecified
// [cfe] Using 'tests/language/part/enhanced_parts/non_tree_part2.dart' as part of 'tests/language/part/enhanced_parts/non_tree_files//non_tree_part1.dart' but its 'part of' declaration says 'tests/language/part/enhanced_parts/non_tree_files/non_tree_part1.dart'.
