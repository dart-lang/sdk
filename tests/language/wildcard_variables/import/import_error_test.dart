// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `_` import prefixes are non-binding. This tests that we can't access the
// top-level declarations of that imported library.

// SharedOptions=--enable-experiment=wildcard-variables

import 'import_lib.dart' as _;

main() {
  var value = 'str';

  _.topLevel;
//^
// [analyzer] unspecified
// [cfe] Undefined name '_'.

  _.C(value);
//^
// [analyzer] unspecified
// [cfe] Undefined name '_'.

  // Private extensions can't be used.
  value.bar;
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'bar' isn't defined for the class 'String'.

  value.fn;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'fn' isn't defined for the class 'String'.
}
