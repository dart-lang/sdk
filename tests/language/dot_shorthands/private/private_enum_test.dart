// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private enums in other
// libraries.

import 'private_enum_lib.dart';

void context(Public_E e) {}

void main() {
  context(.e1);
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.e2);
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

  context(.fact());
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(Public_E.e1); // But this is OK.
}
