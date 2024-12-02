// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When the context type is a language-defined bool
// (`if`, `||`, `while`), using an enum shorthand will match members in the
// `bool` class.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

void main() {
  if (.one) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  while (.two) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  if (.one || .two) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
}
