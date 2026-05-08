// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private mixins in other
// libraries.

import 'private_mixin_lib.dart';

void main() {
  context(.getter);
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'getter'.
  contextAlias(.getter);
  //           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //            ^
  // [cfe] No type was provided to find the dot shorthand 'getter'.

  context(.method());
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'method'.
  contextAlias(.method());
  //            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'method'.
}
