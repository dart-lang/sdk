// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a private library cannot be accessed from outside the platform.

library internal_library_test;

import 'dart:core'; // This loads 'dart:_foreign_helper' and 'patch:core'.
import 'dart:_foreign_helper';
//     ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPORT_INTERNAL_LIBRARY
// [cfe] Can't access platform private library.
//     ^
// [cfe] Not found: 'dart:_foreign_helper'

part 'dart:_foreign_helper';
//   ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.PART_OF_NON_PART
// [cfe] Can't access platform private library.
//   ^
// [cfe] Can't use 'org-dartlang-untranslatable-uri:dart%3A_foreign_helper' as a part, because it has no 'part of' declaration.
//   ^
// [cfe] Not found: 'dart:_foreign_helper'

void main() {
  JS('int', '0');
//^
// [cfe] Method not found: 'JS'.
  JS('int', '0');
//^
// [cfe] Method not found: 'JS'.
}
