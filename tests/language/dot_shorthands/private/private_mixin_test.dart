// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private mixins in other
// libraries.

import 'private_mixin_lib.dart';

void context(Public_M m) {}

void main() {
  context(.getter);
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  context(.method());
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
