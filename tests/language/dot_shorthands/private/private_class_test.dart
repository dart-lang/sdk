// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private classes in other
// libraries.

import 'private_class_lib.dart';

void context(Public_C c) {}
void contextConst(Public_Const c) {}

void main() {
  context(.new());
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.new.asC);
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

  context(.named());
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(Public_C()); // But this is OK.

  contextConst(const .new());
  //                 ^
  // [analyzer] unspecified
  // [cfe] unspecified

  contextConst(const .named());
  //                 ^
  // [analyzer] unspecified
  // [cfe] unspecified

  contextConst(const Public_Const()); // But this is OK.
}
