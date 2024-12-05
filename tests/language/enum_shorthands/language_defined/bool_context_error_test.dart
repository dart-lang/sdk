// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When the context type is a language-defined bool
// (`if`, `||`, `while`), using an enum shorthand will match members in the
// `bool` class.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

extension type const Bool(bool _) implements bool {
  static const Bool isTrue = Bool(true);
  static const Bool isFalse = Bool(false);
}

void main() {
  if (.one) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  if (.isTrue) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  if (!.one) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  if (!.isTrue) {
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
  if (.isTrue || .isFalse) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  if (.one && .two) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  if (.isTrue && .isFalse) {
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
  while (.isTrue) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
  var counter = 0;
  do {
    counter++;
    if (counter > 2) break;
  } while (.two);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
  do {
    counter++;
    if (counter > 2) break;
  } while (.isTrue);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
  assert(.two, '');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
  assert(.isTrue, '');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
