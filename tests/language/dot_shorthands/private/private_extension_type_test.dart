// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private extension types in other
// libraries.

// SharedOptions=--enable-experiment=dot-shorthands

import 'private_extension_type_lib.dart';

void context(Public_E e) {}
void contextConst(Public_ConstE e) {}

void main() {
  context(.new(0));
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.new.asE);
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.getter);
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.method());
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.named(0));
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(Public_E(0)); // But this is OK.

  contextConst(const .new(0));
  //                 ^
  // [analyzer] unspecified
  // [cfe] unspecified

  contextConst(const .named(0));
  //                 ^
  // [analyzer] unspecified
  // [cfe] unspecified

  contextConst(const Public_ConstE(0)); // But this is OK.
}
