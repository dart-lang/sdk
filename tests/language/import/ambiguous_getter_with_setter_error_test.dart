// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reading a getter imported from two libraries is ambiguous, also when one
// of them also declares a setter of the same name.

import 'ambiguous_getter_with_setter_lib1.dart';
import 'ambiguous_getter_with_setter_lib2.dart';

void main() {
  print(x);
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_IMPORT
  // [cfe] 'x' is imported from both 'tests/language/import/ambiguous_getter_with_setter_lib1.dart' and 'tests/language/import/ambiguous_getter_with_setter_lib2.dart'.
}
