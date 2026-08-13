// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private enums in other
// libraries.

import 'private_enum_lib.dart';

void main() {
  context(.e1);
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'e1'.
  contextAlias(.e1);
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //            ^
  // [cfe] No type was provided to find the dot shorthand 'e1'.

  context(.e2);
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'e2'.
  contextAlias(.e2);
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //            ^
  // [cfe] No type was provided to find the dot shorthand 'e2'.

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

  context(.fact());
  //       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'fact'.
  contextAlias(.fact());
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'fact'.

  context(Public_E.e1); // But this is OK.
  contextAlias(Public_E.e1);
}
