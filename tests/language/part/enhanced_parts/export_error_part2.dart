// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'export_error_part1.dart';

// All exported names conflict with lib decl or part1/part3 export.

// Uses `_copy` to export different declaration with the same name.
export "src/lib_decl_copy.dart"
// [error column 1]
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [analyzer] unspecified
// [cfe] 'Cx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'Ex' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'Mx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'Nx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'Tx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'Xx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'fx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'gx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'lx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'mx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'sx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
// [cfe] 'vx' is exported from both 'tests/language/part/enhanced_parts/src/lib_decl.dart' and 'tests/language/part/enhanced_parts/src/lib_decl_copy.dart'.
;
