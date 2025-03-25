// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When the context type is a language-defined bool
// (`if`, `||`, `while`), using a dot shorthand will match members in the
// `bool` class.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

extension type const Bool(bool _) implements bool {
  static const Bool isTrue = Bool(true);
  static const Bool isFalse = Bool(false);
}

void main() {
  if (.one) {
    // ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'one' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (.isTrue) {
    // ^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (!.one) {
    //  ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'one' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (!.isTrue) {
    //  ^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (.one || .two) {
    // ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'one' isn't defined for the type 'bool'.
    //         ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'two' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (.isTrue || .isFalse) {
    // ^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
    //            ^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isFalse' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (.one && .two) {
    // ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'one' isn't defined for the type 'bool'.
    //         ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'two' isn't defined for the type 'bool'.
    print('not ok');
  }
  if (.isTrue && .isFalse) {
    // ^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
    //            ^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isFalse' isn't defined for the type 'bool'.
    print('not ok');
  }
  while (.two) {
    //    ^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'two' isn't defined for the type 'bool'.
    print('not ok');
  }
  while (.isTrue) {
    //    ^^^^^^
    // [analyzer] unspecified
    // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
    print('not ok');
  }
  var counter = 0;
  do {
    counter++;
    if (counter > 2) break;
  } while (.two);
  //        ^^^
  // [analyzer] unspecified
  // [cfe] The static getter or field 'two' isn't defined for the type 'bool'.
  do {
    counter++;
    if (counter > 2) break;
  } while (.isTrue);
  //        ^^^^^^
  // [analyzer] unspecified
  // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
  assert(.two, '');
  //      ^^^
  // [analyzer] unspecified
  // [cfe] The static getter or field 'two' isn't defined for the type 'bool'.
  assert(.isTrue, '');
  //      ^^^^^^
  // [analyzer] unspecified
  // [cfe] The static getter or field 'isTrue' isn't defined for the type 'bool'.
}
