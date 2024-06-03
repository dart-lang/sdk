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
// [cfe] unspecified

  _.C(value);
//^
// [analyzer] unspecified
// [cfe] unspecified

  // Private extensions can't be used.
  value.bar;
//^
// [analyzer] unspecified
// [cfe] unspecified

  value.fn;
//^
// [analyzer] unspecified
// [cfe] unspecified
}
